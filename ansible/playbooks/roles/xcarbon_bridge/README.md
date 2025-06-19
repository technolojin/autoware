# xCarbon Bridge

この role は、VicOne 社製の侵入検知・防止ソフトウェア「xCarbon」と Pilot.Auto を連携させる xCarbon Bridge をビルド・インストールします。

OTA が実行されると Web.Auto Agent の更新に伴い、apt や python パッケージのインストール・更新が行われます。
xCarbon はこれらの更新を検出し、以下のような制御を行います：

    apt パッケージの更新後に生成されたファイルの実行をブロック

    python パッケージに関しては依存関係を含めたファイルの変更をブロック

しかし、未知のパッケージや依存関係を xCarbon のホワイトリストに登録するのは困難です。
そのため OTA によるファームウェアデプロイ中は、xCarbon Bridge が一時的に xCarbon を停止します。

システム再起動後、xCarbon Bridge により xCarbon が再起動され、更新後の状態に対してホワイトリストが再生成されます。

## Overview

![xCarbon Bridge Overview](xcarbon_bridge.drawio.svg)

## Variables

| Variables                       | Default Value                                           | Description                                                                                                                                       |
| ------------------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `xcarbon_bridge_clone_dir`      | `{{ autoware_install_dir }}/src/product/xcarbon_bridge` | xCarbon Bridge をクローンするディレクトリのパス                                                                                                   |
| `xcarbon_bridge_repository`     | `git@github.com:tier4/xcarbon_bridge.git`               | 使用する Git リポジトリの URL                                                                                                                     |
| `xcarbon_bridge_version`        | `v0.1.0`                                                | チェックアウトするリポジトリのバージョン（タグやブランチ）                                                                                        |
| `xcarbon_bridge_install_option` | `--symlink-install`                                     | ビルド時に colcon build に渡すオプション。<br>現在は仮のパラメータとして使用しており、将来的には正式な autoware_install_option に置き換わる予定。 |

## Preparation

playbook への追加例

```yaml
- { role: xcarbon_bridge }
```
