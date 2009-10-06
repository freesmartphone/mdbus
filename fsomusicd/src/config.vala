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
namespace FreeSmartphone.MusicPlayer.Config
{
    public static string get_music_dir()
    {
        return Environment.get_user_special_dir( UserDirectory.MUSIC );
    }
    public static string get_playlist_dir()
    {
        return Path.build_filename( get_config_dir(), "playlists" );
    }
    public static string get_config_dir()
    {
        return Path.build_filename( Environment.get_user_config_dir(), "fsomusicd" );
    }
    public static string get_config_path()
    {
        return Path.build_filename( get_config_dir(), "main.conf" );
    }
    public static string get_sys_config_dir()
    {
        return Path.build_filename( Environment.get_system_config_dirs()[0], "fsodeviced" );
    }


    public const string LAST_PLAYED = "last_played";
    public const string PLAYLIST_MODE = "mode";
    public const string LAST_PLAYLIST = "last_playlist";
    public const string MUSIC_PLAYER_GROUP = "MusicPlayer";
    //Timout for quering the current position in milliseconds
    public const int poll_timeout = 1000;
    //precision of the progress. should be power 0f 10 in nanoseconds
    public const int precision = 1; 
}
