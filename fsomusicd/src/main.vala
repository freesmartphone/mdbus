/* 
 * File Name: 
 * Creation Date: 23-08-2009
 * Last Modified:
 *
 * Authored by Frederik 'playya' Sdun <Frederik.Sdun@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */
using GLib;
using DBus;
using Posix;

namespace FreeSmartphone.MusicPlayer
{
    static MainLoop ml;

    public static int main( string[] args )
    {
        sighandler_t handle;
        try
        {
            Gst.init( ref args );
            ml = new MainLoop( null, false );
            var con = Bus.get( BusType.SESSION );
            var dbus = con.get_object( DBUS_BUS, DBUS_PATH ) as DBusService;
            uint req = dbus.request_name( BUSNAME, (uint)0);
            if( req == DBus.RequestNameReply.PRIMARY_OWNER )
            {
                KeyFile kf = new KeyFile();
                MusicPlayer mp = null;
                try
                {
                    kf.load_from_file( Config.get_config_path(), KeyFileFlags.NONE );
                    mp = new MusicPlayer( con, new ObjectPath( BASE_OBJECT_PATH ), kf );
                }
                catch (GLib.FileError e)
                {
                    create_file_structure();
                    //create a small default config
                    kf.set_string(Config.MUSIC_PLAYER_GROUP, Config.LAST_PLAYED, "");
                    kf.set_string(Config.MUSIC_PLAYER_GROUP, Config.LAST_PLAYLIST, "");
                    var pl = new Playlist.from_dir( "all", kf ,Config.get_music_dir() );
                    mp = new MusicPlayer( con, new ObjectPath( BASE_OBJECT_PATH ), kf );
                    mp.add_playlist( "all", pl );
                }
                con.register_object( BASE_OBJECT_PATH, mp );
                handle = signal( SIGINT, sig_handle );
                ml.run();
                mp = null;
                save_keyfile( kf, Config.get_config_path() );
            }
            else
            {
                error("Can't request Busname: %s", BUSNAME );
            }
        }
        catch (DBus.Error de)
        {
            error("DBus: %s",de.message);
        }
        catch (GLib.Error e)
        {
            error("%s",e.message );
        }
        return 0;
    }
    public static void create_file_structure()
    {
        try
        {
            //0x1A4 = \0644
            DirUtils.create_with_parents( Config.get_playlist_dir(), 0x1ED );
        }
        catch (GLib.Error e)
        {
            debug("Ignoring: %s", e.message);
        }
    }
    public static void save_keyfile( KeyFile kf, string path ) throws FileError
    {
        var fs = FileStream.open( path, "w+" );
        fs.puts( kf.to_data());
    }
    public static void sig_handle( int signal )
    {
        debug("Received signal: %i", signal );
        ml.quit();
    }
}
