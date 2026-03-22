import bpy

class RelaySyncPreferences(bpy.types.AddonPreferences):
    bl_idname = __package__

    relay_enabled: bpy.props.BoolProperty(name='Relay Enabled', default=False)
    relay_poll_interval: bpy.props.FloatProperty(name='Relay Poll Interval', default=0.5, min=0.1)
    relay_inbox_path: bpy.props.StringProperty(name='Relay Inbox Path', subtype='DIR_PATH')
    relay_endpoint: bpy.props.StringProperty(name='Relay Endpoint', default='ws://127.0.0.1:8765')
    reload_settle_delay: bpy.props.FloatProperty(name='Reload Settle Delay', default=0.1, min=0.0)
    auto_sync_enabled: bpy.props.BoolProperty(name='Auto Sync Enabled', default=False)
    debug_sync_logging: bpy.props.BoolProperty(name='Debug Sync Logging', default=False)

    def draw(self, context):
        col = self.layout.column()
        col.prop(self, 'relay_enabled')
        col.prop(self, 'relay_poll_interval')
        col.prop(self, 'relay_inbox_path')
        col.prop(self, 'relay_endpoint')
        col.prop(self, 'reload_settle_delay')
        col.prop(self, 'auto_sync_enabled')
        col.prop(self, 'debug_sync_logging')
