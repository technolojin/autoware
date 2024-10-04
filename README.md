# Pilot.Auto

See [GitHub Pages](https://autowarefoundation.github.io/autoware-documentation/main/).

## 無印pilot-autoのリリースプロセス

[こちら](https://docs.google.com/presentation/d/1N7He7rmJA8PY1P2t7Ood1nxvssh2KtZpkjKLQcNmWHw/edit#slide=id.g26de3aa984c_0_24)を参照ください。

## 使用しているautoware.universe、autoware_launch

- `autoware.universe`: [tier4/のawf-latestブランチ](https://github.com/tier4/autoware.universe/tree/awf-latest) を使用
  - ※このブランチは [GitHub Workflow](https://github.com/tier4/autoware.universe/blob/tier4/main/.github/workflows/sync-awf-latest.yaml) によって作成される
- `autoware_launch`: [tier4/のawf-latestブランチ](https://github.com/tier4/autoware_launch/tree/awf-latest) を使用
  - ※このブランチは [GitHub Workflow](https://github.com/tier4/autoware_launch/blob/tier4/main/.github/workflows/sync-awf-latest.yaml) によって作成される

## MLモデルのダウンロード方法

**注意** : OTAイメージを利用しない場合は必ず下記の手順に従ってMLモデルをダウンロードしてください。ダウンロードしないとpointpaintingなどの物体認識ノードが動きません。

[WebAutoCLI](https://github.com/tier4/WebAutoCLI)を使用するので必要に応じてダウンロードしてください。

以下のコマンドを実行すると、MLモデルがダウンロードされます。

```sh
./get_ml_model.sh
```

## MLモデルを変更する方法

`get_ml_model.sh`の以下の箇所を必要に応じて変更してください。

- `--package-name` : centerpoint/pointpaintingなどのパッケージ名
- `--package-release-name` : xx1/mlmodel/v0.1.0などのパッケージリリース名

パッケージ名やパッケージリリース名は、Autoware Evaluatorから確認できます。

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
