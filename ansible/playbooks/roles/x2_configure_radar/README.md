# X2 configure RADAR

このロールは、RADARのパラメータを設定する systemd サービスを追加します。
サービスは初回ブート時に一度だけ実行され、パラメータを更新します。

## Role in system design

初回ブートかどうかは、`ota_first_boot_flag` ロールによって作成される `/opt/autoware/services/ota_first_boot_flag/.first_boot_done` ファイルの有無で判定されます。
このファイルが存在する場合、本サービスは何も行いません。

また、初回起動時は、現在のRADARのパラメータと設定しようとしているRADARのパラメータを比較して差分があったときのみ更新する。

## Dependency

このロールは、`ota_first_boot_flag` ロールが追加する `rc-local-latest.service` に依存します。
初回以降RADARのアップデートをしないようにするには同サービスにより `.first_boot_done` ファイルが生成される必要があります。

## Usage

以下を Ansible playbookに追加してください。
`- { role: configure_radar }`

### Variables

None

### Preparation

## Related links

rc-local-latest.serviceのPR
<https://github.com/tier4/autoware_ecu_system_setup/pull/1375>

### Remarks

初回起動時に、RADARの各パラメータについて最大10回まで設定を試行します。10回すべてに失敗した場合、このサービスは失敗として扱われます。

`設定しようとしているRADARのパラメータ`は、[ARS548 RDI セットアップ](https://tier4.atlassian.net/wiki/x/J4cAuQ)に基づき、ベンチ環境で事前に設定されたものです。これらの設定は、本ロールに含まれる `get_cfg.sh` によって生成されたcfgファイルを用いて反映されています。

そのため、リンク先の手順書と異なるパラメータでRADARを設定する場合は、ベンチ環境で新たにcfgファイルを生成し、該当ファイルを本ロールに再配置する必要があります。
