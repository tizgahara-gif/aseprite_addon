"""Blender relay polling (timer-based, main-thread safe).
No long-lived threads/sockets in Blender process.
"""
import json
import os
import time
import bpy
from bpy.app.handlers import persistent

STATE = {
    "event_ids": set(),
    "path_registry": {},
    "running": False,
}


def register_export_path(image, export_path, revision=0):
    STATE["path_registry"][os.path.normpath(export_path)] = {
        "image_name": image.name,
        "linked_revision": revision,
        "last_reload_at": 0.0,
        "last_seen_event_id": None,
        "sync_status": "IDLE",
    }


def _safe_reload_image(image_name):
    image = bpy.data.images.get(image_name)
    if not image:
        return False
    image.reload()
    return True


def _stable_file(path, settle_delay):
    if not os.path.exists(path):
        return False
    s1 = (os.path.getmtime(path), os.path.getsize(path))
    time.sleep(max(0.0, settle_delay))
    s2 = (os.path.getmtime(path), os.path.getsize(path))
    return s1 == s2


def poll_relay_inbox():
    prefs = bpy.context.preferences.addons[__package__].preferences
    if not prefs.relay_enabled:
        return prefs.relay_poll_interval

    inbox = prefs.relay_inbox_path
    if not inbox or not os.path.isdir(inbox):
        return prefs.relay_poll_interval

    for name in sorted(os.listdir(inbox)):
        if not name.endswith('.json'):
            continue
        path = os.path.join(inbox, name)
        try:
            with open(path, 'r', encoding='utf-8') as f:
                event = json.load(f)
        except Exception:
            continue

        event_id = event.get('event_id')
        if event_id in STATE['event_ids']:
            continue

        if event.get('type') != 'texture_exported':
            continue

        export_path = os.path.normpath(event.get('export_path', ''))
        reg = STATE['path_registry'].get(export_path)
        if not reg:
            continue

        if not _stable_file(export_path, prefs.reload_settle_delay):
            continue

        if _safe_reload_image(reg['image_name']):
            reg['last_reload_at'] = time.time()
            reg['last_seen_event_id'] = event_id
            reg['sync_status'] = 'RELOADED'
            STATE['event_ids'].add(event_id)

    return prefs.relay_poll_interval


def start_timer():
    if STATE['running']:
        return
    bpy.app.timers.register(poll_relay_inbox, persistent=True)
    STATE['running'] = True


def stop_timer():
    STATE['running'] = False


@persistent
def on_load_post(_):
    start_timer()
