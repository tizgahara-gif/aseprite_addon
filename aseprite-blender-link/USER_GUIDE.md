# USER GUIDE (Aseprite Extension)

## Open Blender Job
- job JSON path を入力して開きます
- parser は `raw.data` 形式と root 直下形式の両方を受理します
- `task.source_path` の画像を開きます

## Validate Texture
- 現在の sprite と job 制約を検証します
- ERROR がある場合は export を止められます

## Export to Blender Target
- `task.export_path` へ PNG を出力します
- Save / Save As とは別操作です
- `GUIDE_*` は export から除外されます

## Toggle Auto Sync
- 編集 change を監視し、debounce 後に自動 export
- 自動 export 後に relay へ `texture_exported` 通知

## Sync Now
- 手動で即時 export + relay 通知

## Preferences
重要項目:
- `relay_url`
- `debounce_seconds`
- `auto_sync_default`
- `auto_validate_before_export`
- `show_sync_status`

## job JSON 受理ルール
- `payload = raw.data or raw`
- 必須: `schema`, `revision`, `revision_tag`, `asset.*`, `task.map_type`, `task.source_path`, `task.export_path`
- `task.guides` は object / array / nil すべて許容

## 既知制約
- relay が未接続でも extension は動作継続（通知のみ失敗）
- Blender add-on 側の導入・UI・operator 詳細はこの repo では扱いません
- Blender 側は `tizgahara-gif/blender_pix` を参照してください
