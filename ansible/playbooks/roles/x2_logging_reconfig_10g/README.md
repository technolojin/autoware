# Logging reconfigure 10G

このroleは、X2 Logging ECUで、10Gb interfaceのLinkup Statusが期待する結果と異なる場合に、自動で再Linkupを実行するスクリプトを組み込みます。

関連:
<https://tier4.atlassian.net/browse/RT0-33635>

## Variables

| Variables                          | default value        | description     |
| ---------------------------------- | -------------------- | --------------- |
| x2_logging_reconfig_10g_interfaces | {enp3s0f0, enp3s0f0} | 対象のinterface |

## Preparation

playbook への追加例

```yaml
- { role: x2_logging_reconfig_10g }
```
