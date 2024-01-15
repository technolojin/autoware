# Pilot.Auto

See [GitHub Pages](https://autowarefoundation.github.io/autoware-documentation/main/).

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
