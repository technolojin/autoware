# Pilot.Auto

See [GitHub Pages](https://autowarefoundation.github.io/autoware-documentation/main/).

## MLモデルのダウンロード方法

pilot-auto無印では[autoware](https://github.com/autowarefoundation/autoware)で配布されているMLモデルを使用します。そのため`./setup-dev-local.sh`で環境構築を終えている場合、追加のダウンロードの必要はありません。その他ケースについては以下を参考にしてください。

### autowarefoudation/autowareのMLモデルを更新したい場合

以下のコマンドを実行してください。

```sh
ansible-galaxy collection install -f -r "ansible-galaxy-requirements.yaml"
```

```sh
ansible-playbook autoware.dev_env.download_artifacts -e "data_dir=$HOME/autoware_data" --ask-become-pass
```

### Evaluatorに登録されているMLモデルを使用したい場合

こちらでは[WebAutoCLI](https://github.com/tier4/WebAutoCLI)を使用するので必要に応じてダウンロードしてください。

まず、`webauto-ci.yml`に`asset-deploy`が記述されていない場合、以下を参考に記述してください。こちらで指定されているMLモデルを次節のスクリプトで読み込みます。この記述はEvaluatorで任意のMLモデルを使用する際でも有効です。

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

以下のコマンドを実行すると、MLモデルがダウンロードされます。

```sh
./get_ml_model.sh
```

## MLモデルを変更する方法

`webauto-ci.yml`内の`ml_packages`の部分を必要に応じて変更してください。もし`ml_packages`が存在していない場合、[MLモデルのダウンロード方法](#mlモデルのダウンロード方法)に従って記述してください。

- `name` : centerpoint/pointpaintingなどのパッケージ名
- `release` : xx1/mlmodel/v0.1.0などのパッケージリリース名

`name`名や`release`名は、Autoware Evaluatorから確認できます。

[pointpaintingの例](https://evaluation.tier4.jp/evaluation/mlpackages/5b56c824-de65-406e-b12f-d7271589cc70?project_id=prd_jt)

## ansibleについて

### ansible playbook

ansibleディレクトリには、2種類のセットアップ用playbookが存在します。

- Autoware Setup
  - local_dev_env.yaml
- ECU Setup
  - ecu_setup.yaml
  - ecu_common.yaml
  - ecu_develop.yaml

また、上記playbookはansible-galaxyを介してroleを設定する形となっています。
そのroleを有するリポジトリをimportするために、[ansible-galaxy-requirements.yaml](https://github.com/tier4/pilot-auto/blob/main/ansible-galaxy-requirements.yaml)があります。
もし追加で参照したいリポジトリがある場合は、このyamlを編集してください。

#### ecu_common.yaml

ECUセットアップにおいて、どのプロジェクトにも必ず必要となるroleをまとめています。

#### ecu_develop.yaml

ECUに開発環境を整えるためのroleをまとめています。
本番環境では不要なものなので、その場合はコメントアウトしても問題ありません。

#### ecu_setup.yaml

実際にECU Setup時に参照されるplaybookです。
ecu_common.yamlとecu_develop.yamlをincludeしています。
また、プロジェクトごとに必要となるroleもある可能性を踏まえて、追加でroleを指定できるようにしています。
例としてsample_roleを設定しているので、これを参考に必要なroleを適宜追加してください。

### playbookの実行

Autoware Setup、およびECU Setupのために、以下のスクリプトが用意されています

- Autoware Setup: setup-dev-env.sh
- ECU Setup: setup-ecu.sh

実行例は以下のとおりです

```bash
# non interactiveかつverboseモードで実行
./setup-local-dev-env.sh -y -v

# interactive、vehicle_id=1234、かつverboseモードで実行
./setup-ecu.sh -v -e vehicle_id=1234

```

## autoware.universeのコードカバレッジ

| Component    | Autoware.Universeでの全体のカバレッジ                                                                                                                                                                                                                                                                           | TIER IV社内のプロダクトで利用されており、かつ自動運転時にリアルタイムで動作するパッケージ                                                                                                                                                                                                                                                                             |
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
