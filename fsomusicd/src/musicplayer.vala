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
        private string current_song
        {
            get { return _current_song; }
            set
            {
                debug( "current song: %s", value );
                this._current_song = value;
                set_playing( value );
            }
        }
        private string _current_song = "";
        private HashTable<ObjectPath,Playlist> playlists;
        private ObjectPath current_playlist
        {
            get{ return _current_playlist; }
            set 
            {
                debug( "current_playlist: %s", value );
                _current_playlist = value;
                var playlist = playlists.lookup( value );
                debug( "playlist: %p %s", playlist, value );
                current_song = playlist.get_next();
            }
        }
        private ObjectPath _current_playlist;
        private string playlist_path;
        private Gst.Pipeline audio_pipeline;
        private Gst.Element playbin;
        private Gst.Bus audio_bus;
        private FreeSmartphone.MusicPlayer.State cur_state = FreeSmartphone.MusicPlayer.State.STOPPED;
        private FreeSmartphone.MusicPlayer.State _state { 
            get{ return this.cur_state; }
            set
            {
                if( value != cur_state )
                {
                    this.cur_state = value;
                    state( value );
                }
            }
        }
        private uint timeout_pos_handle;
        private int _current_position;
        private int current_position
        {
            get{ return _current_position; }
            set
            {
                if( value != _current_position )
                {
                    this._current_position = value;
                    progress( value );
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

            var playlist_dir = Config.get_playlist_dir();
            var dir = Dir.open( playlist_dir );

            debug(" playlist_dir %s %p", playlist_dir, dir );
            for( string file = dir.read_name(); file != null; file = dir.read_name() )
            {
                debug("Adding Playlist %s", file );
                var full_file = Path.build_filename( playlist_dir, file );
                var pl = new Playlist( file, key_file );
                add_playlist( file, pl );
            }
        }
        construct
        {
            playlists = new HashTable<ObjectPath,Playlist>(str_hash, str_equal);
            audio_pipeline = new Pipeline( "audio" );
            playbin = ElementFactory.make( "playbin", "audio_player" );
            audio_pipeline.add( playbin );
            audio_bus = audio_pipeline.get_bus();
            audio_bus.add_watch( bus_callback );
            //var ap_qt = audio_pipeline.get_query_types();
            //debug( "audio_pipeline: %x", (int)ap_qt );
            //debug( "playbin: %x", playbin.get_query_types() );
        }
        ~MusicPlayer()
        {
            save();
            playbin.set_state( Gst.State.NULL );
        }
        //
        // org.freesmartphone.MusicPlayer
        //
        public HashTable<string,GLib.Value?> get_info_for_file( string file ) throws MusicPlayerError, DBus.Error
        {
            return new HashTable<string,GLib.Value?>( str_hash, str_equal );
        }
        public HashTable<string,GLib.Value?> get_playing_info() throws MusicPlayerError, DBus.Error
        {
            return this.cur_song_info;
        }
        public string get_playing() throws MusicPlayerError, DBus.Error
        {
            return current_song;
        }
        public void set_playing( string file ) throws MusicPlayerError, DBus.Error
        {
            this.playbin.set( "uri", "file://" +  file );
            this.audio_pipeline.set_state( Gst.State.READY );
            this._state = FreeSmartphone.MusicPlayer.State.STOPPED;

            this.cur_song_info = new HashTable<string,GLib.Value?>( str_hash, str_equal );
            this.cur_song_info.insert( "filename", file );
            playing_changed( file );
        }
        public void play() throws MusicPlayerError, DBus.Error
        {
            this.audio_pipeline.set_state( Gst.State.PLAYING );
            this._state = FreeSmartphone.MusicPlayer.State.PLAYING;
            timeout_pos_handle = Timeout.add( Config.poll_timeout, position_timeout );
            debug("timout_handl: %u", timeout_pos_handle );
        }
        public void pause() throws MusicPlayerError, DBus.Error
        {
            this.audio_pipeline.set_state( Gst.State.PAUSED );
            this._state = FreeSmartphone.MusicPlayer.State.PAUSED;
        }
        public void stop() throws MusicPlayerError, DBus.Error
        {
            this.audio_pipeline.set_state( Gst.State.READY );
            this._state = FreeSmartphone.MusicPlayer.State.STOPPED;
        }
        public void previous() throws MusicPlayerError, DBus.Error
        {
            var playlist = playlists.lookup( current_playlist );
            if( current_playlist == null )
                 throw new MusicPlayerError.NO_PLAYLIST_SELECTED( "No Playlist Selected" );
            this.current_song = playlist.get_previous();
            if( this.current_song == null )
                 throw new MusicPlayerError.END_OF_LIST( "Playlist %s has no more elements".printf(this.current_playlist));
            play();
        }
        public void next() throws MusicPlayerError, DBus.Error
        {
            if( current_playlist == null )
                 throw new MusicPlayerError.NO_PLAYLIST_SELECTED( "No Playlist Selected" );
            this.current_song = playlists.lookup( current_playlist ).get_next();
            if( this.current_song == null )
                 throw new MusicPlayerError.END_OF_LIST( "Playlist %s has no more elements".printf(this.current_playlist));
            play();
        }
        public void seek_forward( int step ) throws MusicPlayerError, DBus.Error
        {
            jump( current_position + step );
        }
        public void seek_backward( int step ) throws MusicPlayerError, DBus.Error
        {
            jump( current_position - step );
        }
        public void jump( int pos ) throws MusicPlayerError, DBus.Error
        {
            debug( "Jump to position: %i", pos );
            playbin.seek_simple( Gst.Format.TIME, Gst.SeekFlags.NONE, ((int64)pos) * 1000000000 / Config.precision );
        }
        public ObjectPath[] get_playlists()
        {
            var keys = this.playlists.get_keys();
            ObjectPath[] paths = new ObjectPath[keys.length()];
            int i = 0;
            foreach( var key in keys)
            {
                paths[i++] = key;
            }
            return paths;
        }
        public ObjectPath get_current_playlist() throws MusicPlayerError, DBus.Error
        {
            return current_playlist;
        }
        public void set_current_playlist( ObjectPath list )
        {
            var playlist = playlists.lookup( list );
            if( playlist == null )
                 throw new MusicPlayerError.UNKNOWN_PLAYLIST( "Playlist not found for %s".printf( list.rchr( list.len(),'/' ).next_char() ) );
            current_playlist = list;
        }
        public void delete_playlist( ObjectPath list ) throws MusicPlayerError, DBus.Error
        {
            playlists.remove( list );
        }
        public ObjectPath new_playlist( string name ) throws MusicPlayerError, DBus.Error
        {
            var list = new Playlist( name, key_file );
            return add_playlist( name, list );
        }
        public ObjectPath add_playlist( string name, Playlist pl )
        {
            var obj_path = new ObjectPath(playlist_path + name);
            playlists.insert( obj_path, pl );
            playlist( obj_path );
            this.con.register_object( playlist_path + name, pl );
            return obj_path;
        }
        public string[] search( string query )
        {
            return new string[0];
        }
        //
        // None DBus Interface methods
        //
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
        public void save()
        {
            var song = this.current_song == null ? "": this.current_song;
            var list = this.current_playlist == null ? "" : this.current_playlist;
            key_file.set_string( Config.MUSIC_PLAYER_GROUP, Config.LAST_PLAYED, song );
            key_file.set_string( Config.MUSIC_PLAYER_GROUP, Config.LAST_PLAYLIST, list );
            foreach( var k in playlists.get_values() )
            { 
                k.save();
            }
        }

        //
        // Bus Callbacks
        //
        private void foreach_tag (Gst.TagList list, string tag)
        {
            Gst.Value val;
            Gst.TagList.copy_value( out val, list, tag );
            if( ! val.holds( typeof( Gst.Buffer ) ) && ! val.holds( typeof( Gst.Date ) ) )
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
                    GLib.debug( "Message ERROR: %s %s", debug, err.message );
                    break;
                case MessageType.WARNING:
                    GLib.Error err;
                    string debug;
                    message.parse_warning( out err, out debug );
                    GLib.debug( "Message WARNING: %s %s", debug, err.message );
                    break;
                case MessageType.INFO:
                    GLib.Error err;
                    string debug;
                    message.parse_info( out err, out debug );
                    GLib.debug( "Message INFO: %s %s", debug, err.message );
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
                    set_gst_state( newstate );
                    break;
                case MessageType.TAG:
                    Gst.TagList tag_list;
                    message.parse_tag (out tag_list);
                    tag_list.foreach (foreach_tag);
                    break;
                case MessageType.SEGMENT_START:
                    Gst.Format fmt;
                    int64 pos;
                    message.parse_segment_start( out fmt, out pos );
                    debug( "SEGMENT_START: %i %ll", fmt, pos );
                    break;
                case MessageType.DURATION:
                    Gst.Format fmt;
                    int64 dur;
                    message.parse_duration( out fmt, out dur );
                    break;
                case MessageType.CLOCK_PROVIDE:
                    Gst.Clock clk;
                    bool ready;
                    message.parse_clock_provide( out clk, out ready );
                    debug( "CLOCK_PROVIDE: ready:%s type: %s",ready.to_string(), clk.get_type().name() );
                    break;
                case MessageType.NEW_CLOCK:
                    Gst.Clock clk;
                    message.parse_new_clock( out clk );
                    debug("NEW_CLOCK: %s", clk.get_type().name() );
                    break;
                default:
                    debug( "ignored message: %s", message.type.to_string() );
                    break;
            }
            return true;
        }
        public bool position_timeout()
        {
            Gst.Format fmt = Gst.Format.TIME;
            int64 cur;
            if( playbin.query_position( ref fmt, out cur ) )
            {
                current_position = (int)(cur / 1000000000 * Config.precision );
            }
            else
            {
                debug("ERROR in timeout");
            }
            //Call me again
            return true;
        }
    }
}
