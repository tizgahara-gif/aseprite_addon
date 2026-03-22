# Blender–Aseprite Link (MVP)

Blender側コンパニオンアドオンが生成した `job JSON` を Aseprite で安全に開き、制約付きで編集し、`task.export_path` へ書き戻すための Aseprite extension です。

## 概要
- job JSON ベースでジョブを識別
- source/export を明確に分離
- Validate Texture で整合性を確認
- Export to Blender Target は常に `task.export_path` を使用
- palette / guide / layer template をMVP対応

## 必要環境
- Aseprite 1.3+
- Blender側コンパニオンアドオン（job JSON を生成するために必要）
- Aseprite v1.3-rc5 以上（`json.decode()` 利用のため）

## インストール方法
`INSTALL.md` を参照してください。

## .aseprite-extension の作成
1. `aseprite-blender-link/` 直下に `package.json` があることを確認
2. フォルダ内容を zip 化（zipルートに `package.json`）
3. 拡張子を `.aseprite-extension` に変更（例: `aseprite-blender-link-0.1.0.aseprite-extension`）
4. Aseprite の `Edit > Preferences > Extensions > Add Extension` から導入

## job JSON 形式
現行 Blender companion add-on の nested schema (`data.*`) を前提にしています。

必須:
- `data.schema`, `data.revision`, `data.revision_tag`
- `data.asset.object_name`, `data.asset.material_name`, `data.asset.image_name`, `data.asset.image_path`
- `data.task.map_type`, `data.task.source_path`, `data.task.export_path`, `data.task.guides`

任意:
- `data.task.guides.palette_path`
- `data.task.guides.uv_guide_path`
- `data.task.guides.id_map_path`
- `data.task.guides.mask_paths`
- `data.task.locked_constraints`
- `data.task.layer_template`
- `data.task.width`, `data.task.height`, `data.task.color_mode`

`Open Blender Job` は `data.task.source_path` を開き、`Export to Blender Target` は `data.task.export_path` に保存します。

## 基本操作
1. **Open Blender Job** で job JSON を開く
2. 必要なら **Validate Texture** を実行
3. **Export to Blender Target** で Blender 側 target に出力
4. **Open Export Folder** で出力先を確認

## Export の考え方
- Save と Export は分離
- Export は必ず `task.export_path` へ出力
- guide レイヤー（`GUIDE_*`）は export 対象から除外
- overwrite 確認設定を尊重

## 手動検証手順（MVP）
- 正常jobを開く: `tests/fixtures/job_valid.json（必要に応じて先に `tests/fixtures/generate_sample_pngs.py` を実行）`
- 必須欠落で失敗: `job_missing_field.json`
- source欠落で失敗: `job_bad_resolution.json` を編集して存在しない source を指定
- palette_path 欠落: jobから外して warning を確認
- guide読込: `sample_uv_guide.png` を job に紐づけ確認
- export path 確認: `task.export_path` へのPNG出力確認
- resolution mismatch: 開いた後にSpriteサイズ変更して Validate
- required layers 欠落: layer_template 指定 + lock_required_layers true でレイヤー削除後 Validate
- recent jobs: Open 後に Open Recent Job で確認
- preferences: 値変更→再起動後保持確認

## 制約事項
- UIよりデータ整合性を優先
- 失敗時は安全に停止し、部分反映を避ける

## 既知の問題 / 制約
- Blender側自動再読込は未実装
- 双方向同期は未実装
- 自動パレット修正は未実装
- 自動マージは未実装
- 本 extension は job JSON ベースで動作
- 3D見た目の保証は Blender側設定に依存

## 今後の拡張予定
- 外部変更監視の本実装
- map_type拡張プラグイン構造
- ジョブブラウザの詳細フィルタ


## Fixture PNG 生成
バイナリファイル配布制約がある環境では、以下を実行して sample PNG を生成してください。

```bash
python tests/fixtures/generate_sample_pngs.py
```


## Open Blender Job の使い方（UI）
1. メニューから **Open Blender Job** を実行
2. 表示される Dialog の `Job JSON` 入力欄にジョブJSONのフルパスを入力
3. Open を押す
4. path が空/不正、JSON decode失敗、source画像欠落の場合は安全に失敗し、現在のdocumentは破壊しません
