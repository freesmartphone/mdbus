namespace GLibHacks
{
    namespace Bus
    {
        [CCode (cname = "g_bus_watch_name_with_closures", cheader_filename = "gio/gio.h")]
        public static uint watch_name (GLib.BusType bus_type, string name, GLib.BusNameWatcherFlags flags, [CCode (type = "GClosure*")] GLib.BusNameAppearedCallback name_appeared_handler, [CCode (type = "GClosure*")] GLib.BusNameVanishedCallback name_vanished_handler);
        [CCode (cname = "g_bus_watch_name_on_connection_with_closures", cheader_filename = "gio/gio.h")]
        public static uint watch_name_on_connection (GLib.DBusConnection connection, string name, GLib.BusNameWatcherFlags flags, [CCode (type = "GClosure*")] GLib.BusNameAppearedCallback name_appeared_handler, [CCode (type = "GClosure*")] GLib.BusNameVanishedCallback name_vanished_handler);
    }
}
