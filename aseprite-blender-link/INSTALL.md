# INSTALL (Aseprite Extension Only)

この手順は **Aseprite extension の導入専用** です。
Blender 側 add-on の導入は `tizgahara-gif/blender_pix` を参照してください。

## 1) `.aseprite-extension` を作成
1. `aseprite-blender-link/` の中身を zip 化（zip 直下に `package.json` が来ること）
2. 生成zipを `aseprite-blender-link-<version>.aseprite-extension` にリネーム

## 2) Aseprite へ導入
1. Aseprite を開く
2. `Edit > Preferences > Extensions > Add Extension`
3. `.aseprite-extension` を選択してインストール

## 3) 有効化
- Extensions 一覧で `Blender Link` を有効化
- 必要なら Aseprite を再起動

## 4) 最小利用フロー
1. Open Blender Job
2. Validate Texture
3. Export to Blender Target
4. 必要なら Toggle Auto Sync を ON

## 5) relay 設定
Preferences で以下を設定:
- `relay_url`
- `debounce_seconds`
- `auto_sync_default`
