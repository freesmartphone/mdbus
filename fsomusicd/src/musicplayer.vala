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
    public class MusicPlayer:GLib.Object , IMusicPlayer
    {
        private Connection con;
        private ObjectPath path;
        private unowned KeyFile key_file;
        private string current_song = "";
        private HashTable<string,Playlist> playlists;
        private string current_playlist;
        private string playlist_path;

        public MusicPlayer( Connection con, ObjectPath path, KeyFile kf )
        {
            this.con = con;
            this.path = path;
            this.key_file = kf;
            this.playlist_path = ((string)path) + "/Playlists/";
        }
        construct
        {
            playlists = new HashTable<string,Playlist>(str_hash, str_equal);
        }
        public HashTable<string,Value?> get_info_for_file( string file )
        {
            return new HashTable<string,Value?>( str_hash, str_equal );
        }
        public string get_playing()
        {
            return current_song;
        }
        public void set_playing( string file )
        {

        }
        public void play()
        {

        }
        public void pause()
        {

        }
        public void stop()
        {

        }
        public void previous()
        {

        }
        public void next()
        {

        }
        public void seek_forward( int step )
        {

        }
        public void seek_backward( int step )
        {

        }
        public void jump( int pos )
        {

        }
        public ObjectPath[] get_playlists()
        {
            var keys = this.playlists.get_keys();
            int i = 0;
            ObjectPath[] songs = new ObjectPath[keys.length()];
            foreach( var k in keys )
            {
                songs[i++] = new ObjectPath( playlist_path + k );
            }
            return songs;
        }
        public ObjectPath get_current_playlist()
        {
            return new ObjectPath( playlist_path + current_playlist );
        }
        public void delete_playlist( string list )
        {
            playlists.remove( list );
        }
        public ObjectPath new_playlist( string name )
        {
            var list = new Playlist( name, key_file );
            this.con.register_object( playlist_path + name, list );
            playlists.insert( name, list );
            var obj_path = new ObjectPath(playlist_path + name);
            playlist( obj_path );
            return obj_path;
        }
        public void add_playlist( string name, Playlist pl )
        {
            playlists.insert( name, pl );
            this.con.register_object( playlist_path + name, pl );
        }
        public string[] search( string query )
        {
            return new string[0];
        }
    }
}
