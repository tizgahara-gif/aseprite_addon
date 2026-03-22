# Blender Relay Sync Stub

This folder contains a timer-based relay inbox polling stub for Blender add-ons.
- No long-lived threads
- Main-thread safe reload via `bpy.app.timers`
- `texture_exported` events from localhost relay inbox
