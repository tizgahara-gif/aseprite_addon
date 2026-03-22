# Blender Link for Aseprite

**This repository contains only the Aseprite extension.**

このリポジトリは、Aseprite extension 本体の source of truth です。Blender 側 add-on の実装・導入手順・ビルド方法はこの repo では扱いません。

依存先（外部）: `tizgahara-gif/blender_pix`

## 概要
`blender_pix` が生成する job JSON を Aseprite で開き、検証し、Blender 側ターゲットPNGへ安全に書き戻します。

この extension の外部契約（outward contract）:
- Open Blender Job で job JSON を読む
- `task.source_path` を開く
- `task.export_path` に Export / Auto Sync する
- relay_url へ `texture_exported` 通知を送る

## 必要環境
- Aseprite v1.3-rc5 以上（`json.decode()` と script API 利用）
- Blender companion add-on は別 repo (`tizgahara-gif/blender_pix`)

## パッケージ形式
- `package.json` ベースの Aseprite extension
- 配布拡張子: `.aseprite-extension`（実体は zip）

## インストール
`.aseprite-extension` 作成・導入手順は `INSTALL.md` を参照。

## 主要コマンド
- Open Blender Job
- Validate Texture
- Export to Blender Target
- Toggle Auto Sync
- Sync Now
- Open Recent Job / Job Browser / Reload Current Job / Preferences

## 設定（Preferences）
- `relay_url`
- `debounce_seconds`
- `auto_sync_default`
- `auto_validate_before_export`
- `show_sync_status`
- `deflate_enabled`
- `write_log_file`
- `log_file_path`

## job JSON schema（受理ルール）
この extension は以下の両形式を受理します。

1. data wrapper schema: `raw.data.*`
2. root schema: `raw.*`

正規化は `payload = raw.data or raw`。

### 必須
- `schema`
- `revision`
- `revision_tag`
- `asset.object_name`
- `asset.material_name`
- `asset.image_name`
- `asset.image_path`
- `task.map_type`
- `task.source_path`
- `task.export_path`

### 任意
- `task.guides`（object / string array / nil）
- `task.width`, `task.height`, `task.color_mode`
- `task.layer_template`, `task.locked_constraints`

### guides 受理
- array: 1件目を `GUIDE_UV`、2件目以降を `GUIDE_EXTRA_XX`
- object: `uv_guide_path`, `id_map_path`, `mask_paths`, `extra_paths`
- nil: 空ガイド（エラーにしない）

## Save と Export の違い
- Save / Save As: 作業ファイル保存
- Export to Blender Target / Auto Sync: `task.export_path` への書き戻し

## 既知制約
- relay 未接続時は通知失敗をログ警告し、extension自体は継続
- `task.guides` が array の場合、要素意味は位置ルールで解釈
- この repo は Blender add-on 側UIやoperator説明を提供しない

## Manual smoke checks
- `tests/fixtures/job_valid.json`（data wrapper）
- `tests/fixtures/job_valid_root.json`（root schema）
- `python tests/fixtures/generate_sample_pngs.py`（必要時）
