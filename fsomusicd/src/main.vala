/* 
 * File Name: main.vala
 * Creation Date: 23-08-2009
 * Last Modified: 19-11-2009 23:41:19
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

GLib.MainLoop mainloop;
FsoFramework.Logger logger;
FsoFramework.Subsystem subsystem;

namespace FsoMusic
{

    public static int main( string[] args )
    {
        try
        {
            Gst.init( ref args );
            var bin = FsoFramework.Utility.programName();
            logger = FsoFramework.createLogger( bin, bin );
            logger.info( "%s starting up...".printf( bin ) );
            subsystem = new FsoFramework.DBusSubsystem( "fsomusic" );
            subsystem.registerPlugins();
            if( subsystem.registerServiceName( FsoFramework.MusicPlayer.ServiceDBusName ) )
            {
                uint count = subsystem.loadPlugins();
                logger.info("loaded %u plugins".printf( count ) );
                mainloop = new MainLoop( null, false );
                KeyFile kf = new KeyFile();
                MusicPlayer mp = null;
                try
                {
                    kf.load_from_file( Config.get_config_path(), KeyFileFlags.NONE );
                    mp = new MusicPlayer( kf );
                }
                catch (GLib.FileError e)
                {
                    create_file_structure();
                    //create a small default config
                    kf.set_string(Config.MUSIC_PLAYER_GROUP, Config.LAST_PLAYED, "");
                    kf.set_string(Config.MUSIC_PLAYER_GROUP, Config.LAST_PLAYLIST, "");
                    mp = new MusicPlayer( kf );
                }
                subsystem.registerServiceObject( FsoFramework.MusicPlayer.ServiceDBusName,
                                                FsoFramework.MusicPlayer.ServicePathPrefix, mp );
                logger.info( "fsomusicd => mainloop" );
                signal( SIGINT, sig_handle );
                signal( SIGTERM, sig_handle );
                mainloop.run();
                logger.info( "mainloop => fsomusicd" );
                //XXX: Workaround for circular reference
                while( mp.ref_count > 1 )
                {
                    mp.unref();
                    debug( "MusicPlayer countdown: %u", mp.ref_count );
                }
                mp = null;
                save_keyfile( kf, Config.get_config_path() );
            }
            else
            {
                error("Can't request Busname: %s", FsoFramework.MusicPlayer.ServicePathPrefix );
            }
        }
        catch (GLib.Error e)
        {
            error("%s",e.message );
        }
        return 0;
    }
    public static void create_file_structure()
    {
        //0x1A4 = \0644
        DirUtils.create_with_parents( Config.get_playlist_dir(), 0x1ED );
    }
    public static void save_keyfile( KeyFile kf, string path ) throws FileError
    {
        var fs = FileStream.open( path, "w+" );
        fs.puts( kf.to_data());
    }
    public static void sig_handle( int signal )
    {
        logger.debug("Received signal: %i".printf( signal ) );
        mainloop.quit();
    }
}
