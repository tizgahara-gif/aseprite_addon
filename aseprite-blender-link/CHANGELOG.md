# CHANGELOG

## 0.2.0 - 2026-03-22
- Switched to proper Aseprite plugin lifecycle with `init(plugin)` / `exit(plugin)` in `main.lua`.
- Added global module loader rooted at extension folder to avoid runtime path issues.
- Migrated settings persistence to `plugin.preferences` (no external config file dependency).
- Expanded state fields to include required job metadata fields.
- Added json.decode availability gate for Aseprite version compatibility (v1.3-rc5+ expected).
- Improved reload flow with revision-change detection.
- Moved fixtures to `tests/fixtures`.
- Updated docs with `.aseprite-extension` packaging and install instructions.

## 0.1.0 - 2026-03-22
- MVP scaffold for Blender–Aseprite file-based extension.
- Implemented job parser, validator, exporter, preferences, recent jobs.
- Added commands: open/reload/validate/export/job browser/open export folder.
- Added sample fixtures and docs.
