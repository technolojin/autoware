# hold storage

【RQX-58G向け】特定のストレージ（RQX-58GではeMMC）をread-onlyで明示的にマウントする。

## Role in system design

`hold_storage`は、特定の記憶媒体を所定のディレクトリに明示的にread-onlyでマウントし、他の操作を受け付けないようにするためのロールである。

## Dependency

## Usage

### Variables

#### 必須

- hold_storage_list: 以下の構造体リスト形式で指定する
  - src: マウントしたいデバイスのディレクトリ
  - dest: マウント先ディレクトリ

#### オプション

Nothing.

### Preparation

playbook への追加例

`- { role: hold_storage, tags: [hold_storage] }`

## Related links

### Remarks

hold_storageの内容を反映させるには, ロールの実行後に再起動するか, 以下のコマンドを実施する必要がある.

```bash
sudo mount -a
```
