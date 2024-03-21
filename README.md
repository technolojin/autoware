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
