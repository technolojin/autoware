# Pilot.Auto

[![build-and-test](https://github.com/tier4/pilot-auto/actions/workflows/build-and-test.yaml/badge.svg)](https://github.com/tier4/pilot-auto/actions/workflows/build-and-test.yaml) (nightly build from `update-resolved-repos-main` branch)

See [GitHub Pages](https://autowarefoundation.github.io/autoware-documentation/main/).

## Pilot.Auto のリリース

- Pilot.Auto のバージョンは、`vx.y.z` の形式で表現する。
- Pilot.Auto のリリースは、4 週間に一回実施する。このとき、バージョン名の `y` の部分をインクリメントする。
  - 致命的な不具合が含まれる場合は、hotfix を導入して `z` の部分をインクリメントしたバージョンをリリースする場合がある。
- [.release_info.yaml](./.release_info.yaml) の `released_repositories` に記載されている子リポジトリは、Pilot.Auto のリリースと同じタイミングでタグを設定する。
- リリースを行うとき、[リリーステスト評価内容](https://tier4.atlassian.net/wiki/x/xAHqww) に記載された項目を評価する。
- リリースは、[Release flow for Vanilla product](https://tier4.atlassian.net/wiki/x/zoAbuw) に従って実施する。

## Pilot.Auto のブランチについて

- `main`
  - autowarefoundation の最新状態を常に取り込んでいるブランチ
- `beta/vx.y`
  - `vx.y.z` のリリース評価のためのブランチ

## 使用している autoware.universe、autoware_launch

- `autoware.universe`: [tier4/の awf-latest ブランチ](https://github.com/tier4/autoware.universe/tree/awf-latest) を使用
  - ※このブランチは [GitHub Workflow](https://github.com/tier4/autoware.universe/blob/tier4/main/.github/workflows/sync-awf-latest.yaml) によって作成される
- `autoware_launch`: [tier4/の awf-latest ブランチ](https://github.com/tier4/autoware_launch/tree/awf-latest) を使用
  - ※このブランチは [GitHub Workflow](https://github.com/tier4/autoware_launch/blob/tier4/main/.github/workflows/sync-awf-latest.yaml) によって作成される

## autoware.universe のブランチ戦略

[こちら](./docs/universe.md)を参照してください。

[English version](./docs/universe_en.md)

## ML モデルのダウンロード方法

pilot-auto 無印では、基本的に[autoware](https://github.com/autowarefoundation/autoware)で配布されている ML モデルのみを使用します。しかし、`./setup-dev-local.sh`は環境構築のみを行うためダウンロードされません。以下を参考にダウンロードしてください。

### autowarefoundation/autoware の ML モデル使用したい場合

以下のコマンドを実行してください。

```sh
ansible-galaxy collection install -f -r "ansible-galaxy-requirements.yaml"
```

```sh
ansible-playbook autoware.dev_env.download_artifacts -e "data_dir=$HOME/autoware_data" --ask-become-pass
```

### Evaluator に登録されている ML モデルを使用したい場合

こちらでは[WebAutoCLI](https://github.com/tier4/WebAutoCLI)を使用するので必要に応じてダウンロードしてください。

まず、`webauto-ci.yml`に`asset-deploy`が記述されていない場合、以下を参考に記述してください。こちらで指定されている ML モデルを次節のスクリプトで読み込みます。この記述は Evaluator で任意の ML モデルを使用する際でも有効です。

例

```yaml
artifacts:
  - name: main
    build:
      phases:
        - name: environment-setup
        - name: autoware-setup
        - name: autoware-build
        - name: asset-deploy
          user: autoware
          exec: ./.webauto-ci/main/asset-deploy/run.sh
          ml_packages:  ml_packages:
            - name: centerpoint
              release: base/1.0
            - name: yolox
              release: common/mlmodel/v0.1.0
```

以下のコマンドを実行すると、ML モデルがダウンロードされます。

```sh
./get_ml_model.sh
```

## ML モデルを変更する方法

`webauto-ci.yml`内の`ml_packages`の部分を必要に応じて変更してください。もし`ml_packages`が存在していない場合、[ML モデルのダウンロード方法](#ml-モデルのダウンロード方法)に従って記述してください。

- `name` : centerpoint/pointpainting などのパッケージ名
- `release` : xx1/mlmodel/v0.1.0 などのパッケージリリース名

`name`名や`release`名は、Autoware Evaluator から確認できます。

[pointpainting の例](https://evaluation.tier4.jp/evaluation/mlpackages/5b56c824-de65-406e-b12f-d7271589cc70?project_id=prd_jt)

## ansible について

### ansible playbook

ansible ディレクトリには、2 種類のセットアップ用 playbook が存在します。

- Autoware Setup
  - local_dev_env.yaml
- ECU Setup
  - ecu_setup.yaml
  - ecu_common.yaml
  - ecu_develop.yaml

また、上記 playbook は ansible-galaxy を介して role を設定する形となっています。
その role を有するリポジトリを import するために、[ansible-galaxy-requirements.yaml](https://github.com/tier4/pilot-auto/blob/main/ansible-galaxy-requirements.yaml)があります。
もし追加で参照したいリポジトリがある場合は、この yaml を編集してください。

#### ecu_common.yaml

ECU セットアップにおいて、どのプロジェクトにも必ず必要となる role をまとめています。

#### ecu_develop.yaml

ECU に開発環境を整えるための role をまとめています。
本番環境では不要なものなので、その場合はコメントアウトしても問題ありません。

#### ecu_setup.yaml

実際に ECU Setup 時に参照される playbook です。
ecu_common.yaml と ecu_develop.yaml を include しています。
また、プロジェクトごとに必要となる role もある可能性を踏まえて、追加で role を指定できるようにしています。
例として sample_role を設定しているので、これを参考に必要な role を適宜追加してください。

### playbook の実行

Autoware Setup、および ECU Setup のために、以下のスクリプトが用意されています

- Autoware Setup: setup-dev-env.sh
- ECU Setup: setup-ecu.sh

実行例は以下のとおりです

```bash
# non interactiveかつverboseモードで実行
./setup-local-dev-env.sh -y -v

# interactive、vehicle_id=1234、かつverboseモードで実行
./setup-ecu.sh -v -e vehicle_id=1234

```

## autoware.universe のコードカバレッジ

| Component    | Autoware.Universe での全体のカバレッジ                                                                                                                                                                                                                                                                          | TIER IV 社内のプロダクトで利用されており、かつ自動運転時にリアルタイムで動作するパッケージ                                                                                                                                                                                                                                                                            |
| ------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Common       | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Common%20Packages&query=$.[0].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Common%20Packages)             | Same                                                                                                                                                                                                                                                                                                                                                                  |
| Control      | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Control%20Packages&query=$.[1].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Control%20Packages)           | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Control%20TIER%20%20IV%20Maintained%20Packages&query=$.[12].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Control%20TIER%20IV%20Maintained%20Packages)           |
| Evaluator    | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Evaluator%20Packages&query=$.[2].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Evaluator%20Packages)       | Same                                                                                                                                                                                                                                                                                                                                                                  |
| Launch       | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Launch%20Packages&query=$.[3].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Launch%20Packages)             | Same                                                                                                                                                                                                                                                                                                                                                                  |
| Localization | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Localization%20Packages&query=$.[4].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Localization%20Packages) | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Localization%20TIER%20%20IV%20Maintained%20Packages&query=$.[13].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Localization%20TIER%20IV%20Maintained%20Packages) |
| Map          | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Map%20Packages&query=$.[5].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Map%20Packages)                   | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Map%20TIER%20%20IV%20Maintained%20Packages&query=$.[14].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Map%20TIER%20IV%20Maintained%20Packages)                   |
| Perception   | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Perception%20Packages&query=$.[6].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Perception%20Packages)     | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Perception%20TIER%20%20IV%20Maintained%20Packages&query=$.[15].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Perception%20TIER%20IV%20Maintained%20Packages)     |
| Planning     | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Planning%20Packages&query=$.[7].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Planning%20Packages)         | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Planning%20TIER%20%20IV%20Maintained%20Packages&query=$.[16].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Planning%20TIER%20IV%20Maintained%20Packages)         |
| Sensing      | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Sensing%20Packages&query=$.[8].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Sensing%20Packages)           | Same                                                                                                                                                                                                                                                                                                                                                                  |
| Simulator    | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Simulator%20Packages&query=$.[9].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Simulator%20Packages)       | Same                                                                                                                                                                                                                                                                                                                                                                  |
| System       | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=System%20Packages&query=$.[10].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=System%20Packages)            | Same                                                                                                                                                                                                                                                                                                                                                                  |
| Vehicle      | [![codecov](https://img.shields.io/badge/dynamic/json?url=https://codecov.io/api/v2/github/autowarefoundation/repos/autoware.universe/components&label=Vehicle%20Packages&query=$.[11].coverage)](https://app.codecov.io/gh/autowarefoundation/autoware.universe?components%5B0%5D=Vehicle%20Packages)          | Same                                                                                                                                                                                                                                                                                                                                                                  |
