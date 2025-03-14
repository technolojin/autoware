# x2_cyclonedds_for_redundancy

cycloneddsの冗長構成用configファイルの追加を行う。

## Role in system design

cycloneddsを用いて通信する際に、network_interface_addressなど、各プロダクトによって異なる設定を行う必要がある。

`x2_cyclonedds_for_redundancy`は、これらの設定を行うロールである。

## Dependency

## Usage

### Variables

| Variables                          | Default Value                        | Roles                                                      |
| ---------------------------------- | ------------------------------------ | ---------------------------------------------------------- |
| network_interface                  | `{ address: lo, priority: default }` | 通信に使用するnetwork interface、priority(Ubuntu22.04のみ) |
| minimum_socket_receive_buffer_size | 20MB                                 | ソケットの受信バッファのサイズ                             |
| minimum_socket_send_buffer_size    | default                              | ソケットの送信バッファのサイズ                             |
| max_message_size                   | 65500B                               | UDPペイロードの最大サイズ                                  |
| fragment_size                      | 4000B                                | DDSI sample フラグメントのサイズ                           |
| max_rexmit_message_size            | 1456B                                | 再送信時のUDPペイロードの最大サイズ                        |
| water_mark_whc_high                | 500kB                                | ここまで達するとwriterが中断される水位                     |
| water_mark_whc_low                 | 1kB                                  | ここまで達すると中断されたwriterが再開される水位           |

### Preparation

playbook への追加例
`- { role: x2_cyclonedds_for_redundancy, tags: [x2_cyclonedds_for_redundancy] }`

## Related links

[Cyclone DDSの設定ファイルの参考資料](https://github.com/eclipse-cyclonedds/cyclonedds/blob/master/docs/manual/options.md)

カーネルパラメータの参考資料

- [Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/6/html/performance_tuning_guide/s-network-dont-adjust-defaults)
- [Sysctl Explorer](https://sysctl-explorer.net/net/ipv4/)

### Remarks
