import bpy
from .preferences import RelaySyncPreferences
from .panels import VIEW3D_PT_relay_sync_status
from . import relay_sync

CLASSES = [RelaySyncPreferences, VIEW3D_PT_relay_sync_status]


def register():
    for c in CLASSES:
        bpy.utils.register_class(c)
    bpy.app.handlers.load_post.append(relay_sync.on_load_post)
    relay_sync.start_timer()


def unregister():
    relay_sync.stop_timer()
    if relay_sync.on_load_post in bpy.app.handlers.load_post:
        bpy.app.handlers.load_post.remove(relay_sync.on_load_post)
    for c in reversed(CLASSES):
        bpy.utils.unregister_class(c)
