import bpy

class VIEW3D_PT_relay_sync_status(bpy.types.Panel):
    bl_label = 'Relay Auto Sync'
    bl_space_type = 'VIEW_3D'
    bl_region_type = 'UI'
    bl_category = 'Blender Link'

    def draw(self, context):
        prefs = context.preferences.addons[__package__].preferences
        col = self.layout.column()
        col.label(text=f"Relay: {'ON' if prefs.relay_enabled else 'OFF'}")
        col.label(text=f"Auto Sync: {'ON' if prefs.auto_sync_enabled else 'OFF'}")
        col.prop(prefs, 'relay_poll_interval')
