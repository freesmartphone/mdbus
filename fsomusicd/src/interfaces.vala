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

namespace FreeSmartphone.MusicPlayer
{
    public enum State
    {
        PLAYING,
        PAUSED,
        STOPPED
    }
    public errordomain MusicPlayerError
    {
        NO_FILE_SELECTED,
        NO_PLAYLIST_SELECTED,
        END_OF_LIST,
        UNKNOWN_PLAYLIST,
        PLAYLIST_OUT_OF_FILES,
        FILE_NOT_FOUND
    }
    public const string BASE_OBJECT_PATH = "/org/freesmartphone/MusicPlayer";
    public const string BUSNAME = "org.freesmartphone.omusicd";

    [DBus (name="org.freesmartphone.MusicPlayer")]
    public interface IMusicPlayer: GLib.Object
    {
        public abstract HashTable<string,Value?> get_info_for_file( string file ) throws MusicPlayerError, DBus.Error;
        public abstract string get_playing() throws MusicPlayerError, DBus.Error;
        public abstract GLib.HashTable<string,Value?> get_playing_info() throws MusicPlayerError, DBus.Error;
        public abstract void set_playing( string file ) throws MusicPlayerError, DBus.Error;
        public abstract void play() throws MusicPlayerError, DBus.Error;
        public abstract void pause() throws MusicPlayerError, DBus.Error;
        public abstract void stop() throws MusicPlayerError, DBus.Error;
        public abstract void previous() throws MusicPlayerError, DBus.Error;
        public abstract void next() throws MusicPlayerError, DBus.Error;
        public abstract void seek_forward( int step ) throws MusicPlayerError, DBus.Error;
        public abstract void seek_backward( int step ) throws MusicPlayerError, DBus.Error;
        public abstract void jump( int pos ) throws MusicPlayerError, DBus.Error;
        public abstract ObjectPath[] get_playlists() throws MusicPlayerError, DBus.Error;
        public abstract ObjectPath get_current_playlist() throws MusicPlayerError, DBus.Error;
        public abstract void set_current_playlist( ObjectPath list ) throws MusicPlayerError, DBus.Error;
        public abstract void delete_playlist( ObjectPath list ) throws MusicPlayerError, DBus.Error;
        public abstract ObjectPath new_playlist( string name ) throws MusicPlayerError, DBus.Error;
        public abstract string[] search( string query ) throws MusicPlayerError, DBus.Error;
        public abstract int get_volume() throws DBus.Error;
        public abstract void set_volume( int vol ) throws MusicPlayerError, DBus.Error;
        public abstract signal void progress( int progress );
        public abstract signal void playing_changed( string file );
        public abstract signal void state( State state );
        public abstract signal void playlist_added( ObjectPath path );
        public abstract signal void playlist_removed( ObjectPath path );
    }
    [DBus (name="org.freesmartphone.MusicPlayer.Playlist")]
    public interface IPlaylist: GLib.Object
    {
        public abstract string[] get_files() throws PlaylistError, DBus.Error;
        public abstract void insert( int position, string file ) throws PlaylistError, DBus.Error;
        public abstract void remove( int position ) throws PlaylistError, DBus.Error;
        public abstract void insert_dir( int position, string dir, bool recursive ) throws PlaylistError, DBus.Error;
        public abstract string get_at_position( int position ) throws PlaylistError, DBus.Error;
        public abstract void load_from_file( string filename ) throws PlaylistError, DBus.Error;
        public abstract string get_name() throws PlaylistError, DBus.Error;
        public abstract void change_name( string new_name ) throws PlaylistError, DBus.Error;
        public abstract signal void name( string name );
        public abstract signal void playing( string file );
        public abstract signal void deleted();
        public abstract signal void file_removed( int position );
        public abstract signal void file_added( int position, string filename);
    }
    public errordomain PlaylistError
    {
        FILE_NOT_FOUND,
        OUT_OF_RANGE,
        FILETYPE_NOT_SUPPORTED,
        EMPTY,
        NO_FILE_SELECTED,
        OUT_OF_FILES
    }

    [DBus (name = "org.freedesktop.DBus")]
    public interface DBusService : GLib.Object 
    {
        public abstract string hello() throws DBus.Error;
        public abstract uint request_name(string param0, uint param1) throws DBus.Error;
        public abstract uint release_name(string param0) throws DBus.Error;
        public abstract uint start_service_by_name(string param0, uint param1) throws DBus.Error;
        public abstract void update_activation_environment(GLib.HashTable<string, string> param0) throws DBus.Error;
        public abstract bool name_has_owner(string param0) throws DBus.Error;
        public abstract string[] list_names() throws DBus.Error;
        public abstract string[] list_activatable_names() throws DBus.Error;
        public abstract void add_match(string param0) throws DBus.Error;
        public abstract void remove_match(string param0) throws DBus.Error;
        public abstract string get_name_owner(string param0) throws DBus.Error;
        public abstract string[] list_queued_owners(string param0) throws DBus.Error;
        public abstract uint get_connection_unix_user(string param0) throws DBus.Error;
        public abstract uint get_connection_unix_process_i_d(string param0) throws DBus.Error;
        public abstract uchar[] get_adt_audit_session_data(string param0) throws DBus.Error;
        public abstract uchar[] get_connection_s_e_linux_security_context(string param0) throws DBus.Error;
        public abstract void reload_config() throws DBus.Error;
        public abstract string get_id() throws DBus.Error;
        public signal void name_owner_changed(string param0, string param1, string param2);
        public signal void name_lost(string param0);
        public signal void name_acquired(string param0);
    }
    public const string DBUS_PATH = "/org/freedesktop/DBus";
    public const string DBUS_BUS = "org.freedesktop.DBus";
}
