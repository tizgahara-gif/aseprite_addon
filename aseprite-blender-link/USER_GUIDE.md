## Aseprite バージョン前提
- 本extensionは **Aseprite v1.3-rc5 以上** を前提にしています（`json.decode()` 使用）。

# USER GUIDE

## Open Blender Job
- メニュー実行後、入力ダイアログに `job JSON path` を入力して開きます。
- extension は nested schema を読み取り、`task.source_path` を source として開きます。
- path は `plugin.preferences.default_job_folder` を初期値として補助表示します。
- path不正/JSON不正/source欠落時はエラーダイアログを表示し、既存documentは変更しません。
- palette / guides / layer template を必要に応じて適用します。

## Job Browser
- ジョブフォルダを指定し、JSON一覧から開きます。
- 不正JSONは `[INVALID]` 表示されます。

## Validate Texture
- 解像度、color mode、required layers、export path などを検証します。
- ERROR は export ブロック、WARNING は続行可能です。

## Export to Blender Target
- `task.export_path` へ PNG を出力します。
- `GUIDE_*` レイヤーは一時的に非表示化して除外します。

## ガイドレイヤーの扱い
- `GUIDE_UV`, `GUIDE_ID`, `GUIDE_MASK_XX` として追加されます。
- 補助用途のみで、本体レイヤーに結合しないでください。

## よくある失敗
- 必須フィールド不足のJSON
- source PNG が存在しない
- export先フォルダが存在しない
- lock_required_layers 下で必須レイヤー不足

## トラブルシュート
- Preferences で `enable_debug_mode` を有効化
- `write_log_file` + `log_file_path` を設定してログ確認
- 必要に応じて job JSON の相対パスを絶対パスへ変更


## Save と Export の違い
- `Save` / `Save As` は作業ファイルの保存です。
- `Export to Blender Target` は Blender 側監視先 (`task.export_path`) への書き戻しです。
- 本extensionは両者を分離し、Export時のみ target PNG を更新します。


## Fixture PNG 生成
バイナリファイル配布制約がある環境では、以下を実行して sample PNG を生成してください。

```bash
python tests/fixtures/generate_sample_pngs.py
```
