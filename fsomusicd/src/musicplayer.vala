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
using Gst;

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
        private Pipeline audio_pipeline;
        private Element playbin;
        private Gst.Bus audio_bus;
        private FreeSmartphone.MusicPlayer.State cur_state = FreeSmartphone.MusicPlayer.State.STOPPED;
        private FreeSmartphone.MusicPlayer.State _state { 
            get{ return this.cur_state; }
            set
            {
                if( value != cur_state )
                {
                    debug("State changed");
                    this.cur_state = value;
                    state( value );
                }
            }
        }

        private HashTable<string,GLib.Value?> cur_song_info;


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
            audio_pipeline = new Pipeline( "audio" );
            playbin = ElementFactory.make( "playbin", "audio_player" );
            audio_pipeline.add( playbin );
            audio_bus = audio_pipeline.get_bus();
            audio_bus.add_watch( bus_callback );
        }
        //
        // org.freesmartphone.MusicPlayer
        //
        public HashTable<string,GLib.Value?> get_info_for_file( string file )
        {
            return new HashTable<string,GLib.Value?>( str_hash, str_equal );
        }
        public string get_playing()
        {
            return current_song;
        }
        public void set_playing( string file )
        {
            this.current_song = file;
            this.audio_pipeline.set_state( Gst.State.READY );
            this.playbin.set( "uri", "file://" +  file );
            this._state = FreeSmartphone.MusicPlayer.State.STOPPED;

            this.cur_song_info = new HashTable<string,GLib.Value?>( str_hash, str_equal );
            this.cur_song_info.insert( "filename", file );
        }
        public void play()
        {
            this.audio_pipeline.set_state( Gst.State.PLAYING );
            this._state = FreeSmartphone.MusicPlayer.State.PLAYING;
        }
        public void pause()
        {
            this.audio_pipeline.set_state( Gst.State.PAUSED );
            this._state = FreeSmartphone.MusicPlayer.State.PAUSED;
        }
        public void stop()
        {
            this.audio_pipeline.set_state( Gst.State.READY );
            this._state = FreeSmartphone.MusicPlayer.State.STOPPED;
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
        //
        // None DBus Interface methods
        //
        public void add_playlist( string name, Playlist pl )
        {
            playlists.insert( name, pl );
            this.con.register_object( playlist_path + name, pl );
        }
        public string[] search( string query )
        {
            return new string[0];
        }
        public void set_gst_state( Gst.State s )
        {
            switch( s )
            {
                case Gst.State.READY:
                case Gst.State.NULL:
                case Gst.State.VOID_PENDING:
                    _state = FreeSmartphone.MusicPlayer.State.STOPPED;
                    break;
                case Gst.State.PAUSED:
                    _state = FreeSmartphone.MusicPlayer.State.PAUSED;
                    break;
                case Gst.State.PLAYING:
                    _state = FreeSmartphone.MusicPlayer.State.PLAYING;
                    break;
                default:
                    break;
            }
        }

        //
        // Bus Callbacks
        //
        private void foreach_tag (Gst.TagList list, string tag)
        {
            string val;
            list.get_string( tag, out val );
            cur_song_info.insert( tag, val );
        }
        private bool bus_callback (Gst.Bus bus, Gst.Message message)
        {
            switch( message.type )
            {
                case MessageType.ERROR:
                    GLib.Error err;
                    string debug;
                    message.parse_error( out err, out debug );
                    GLib.debug( "Message Error: %s %s", debug, err.message );
                    break;
                case MessageType.EOS:
                    debug("End of stream");
                    next();
                    break;
                case MessageType.STATE_CHANGED:
                    Gst.State oldstate;
                    Gst.State newstate;
                    Gst.State pending;
                    message.parse_state_changed( out oldstate, out newstate, out pending );
                    debug("Bus.State: %s %s %s", oldstate.to_string(), newstate.to_string(), pending.to_string() );
                    break;
            }
            return true;
        }
    }
}
