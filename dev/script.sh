#!/bin/bash
# shellcheck disable=SC1091
# スクリプトのパス
script_dir=$(
    cd "$(dirname "$0")" || exit
    pwd
)
echo "$script_dir"
# ネットワークインターフェース一覧（lo除外）
mapfile -t interfaces < <(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)

# zenity に渡すための引数配列
zenity_args=(--list --title="Select Network Interface" --column="Interfaces")

# 各インターフェースを引数として追加
for iface in "${interfaces[@]}"; do
    zenity_args+=("$iface")
done

# interfaceの選択
interface=$(zenity "${zenity_args[@]}")

echo "========================"
echo "selected interface: $interface"
echo "========================"

# キャンセル時の処理
if [[ -z $interface ]]; then
    zenity --error --text="No interface selected. Exiting."
    exit 1
fi

# IPアドレス設定
sudo ip addr add 192.168.30.123/24 dev "$interface"
sudo ip link set "$interface" up

# プレースホルダを置き換えて /tmp に出力
sudo chown -R "$USER:$USER" /tmp
sed "s|<DEVICE_NAME>|$interface|g" cyclonedds.xml.template >/tmp/cyclonedds.xml
echo "Generated /tmp/cyclonedds.xml with interface=$interface"

# システム全体のネットワーク設定
sudo sysctl -w net.core.rmem_max=2147483647          # 2 GiB, default is 208 KiB
sudo sysctl -w net.ipv4.ipfrag_time=3                # 秒単位, デフォルト30秒
sudo sysctl -w net.ipv4.ipfrag_high_thresh=134217728 # 128 MiB, デフォルト256 KiB

# cycloneddsの設定
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export CYCLONEDDS_URI=file:///tmp/cyclonedds.xml
export ROS_DOMAIN_ID=1

sudo ip link set "$interface" multicast on

# source
setup_script="$script_dir/../install/setup.bash"
if [[ -f $setup_script ]]; then
    # shellcheck source=../install/setup.bash
    source "$setup_script"
else
    echo "Error: $setup_script が見つかりません"
    exit 1
fi

# topicが得られるまで待機
until ros2 topic list | grep -q "/tf"; do
    echo "Waiting for /tf topic to appear..."
    sleep 0.5
done
echo "/tf topic discovered. Launching RViz."

# Rviz起動
rviz2 -d "$script_dir/../src/autoware/launcher/autoware_launch/rviz/autoware_x2.rviz"
