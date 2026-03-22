# INSTALL

## 1) .aseprite-extension の作成
1. `aseprite-blender-link` フォルダの中身を zip 化（zipルートに `package.json`）
2. `aseprite-blender-link-0.1.0.aseprite-extension` にリネーム

## 2) extension の配置
1. Aseprite で `Edit > Preferences > Extensions > Add Extension`
2. `.aseprite-extension` もしくは zip を選択して追加

## 3) 有効化方法
- Extensions一覧で `Blender Link` を有効化
- 再起動を要求された場合は再起動

## 4) 設定画面の場所
- `File > Scripts > Preferences`（Blender Link 項目）

## 5) サンプル job の開き方
- `Open Blender Job` で `tests/fixtures/job_valid.json（必要に応じて先に `tests/fixtures/generate_sample_pngs.py` を実行）` を選択

## 6) 最初の export まで
1. `Open Blender Job`
2. 必要なら描画編集
3. `Validate Texture`
4. `Export to Blender Target`
5. `Open Export Folder` で出力確認


## Fixture PNG 生成
バイナリファイル配布制約がある環境では、以下を実行して sample PNG を生成してください。

```bash
python tests/fixtures/generate_sample_pngs.py
```


## localhost relay 方式
- Aseprite は WebSocket client として `relay_url` へ接続します。
- 自動export後に `texture_exported` JSON を relay へ通知します。
- Blender 側は relay inbox(JSON) を timer polling して `image.reload()` します。


## Schema 互換モード
- parser は `raw.data or raw` で payload を決定し、
  - data wrapper 付き schema (`{ "data": ... }`)
  - root 直下 schema
  の両方に対応します。
- `task.guides` は object / string array / nil の全ケースを許容します。
  - array: 1件目を `GUIDE_UV`、2件目以降を `GUIDE_EXTRA_XX`
  - object: `uv_guide_path`, `id_map_path`, `mask_paths`, `extra_paths` を利用
  - nil: 空ガイドとして扱いエラーにしません。
