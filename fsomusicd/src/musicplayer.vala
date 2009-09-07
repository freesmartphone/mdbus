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
        private Connection conn;
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
                _current_playlist = value;
                var playlist = playlists.lookup( value );
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
        private HashTable<string,GLib.Value?> file_info;


        public MusicPlayer( Connection con, ObjectPath path, KeyFile kf )
        {
            this.conn = con;
            this.path = path;
            this.key_file = kf;
            this.playlist_path = ((string)path) + "/Playlists/";

            var playlist_dir = Config.get_playlist_dir();
            try
            {
                var dir = Dir.open( playlist_dir );

                for( string file = dir.read_name(); file != null; file = dir.read_name() )
                {
                    debug( "FILENAME: %s", file );
                    var pl = new Playlist( file, key_file );
                    add_playlist( file, pl );
                }
            }
            catch (GLib.Error e)
            {
                debug( "Open playlists: %s", e.message );
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
            if( ! FileUtils.test( file, FileTest.EXISTS ) )
                 throw new MusicPlayerError.FILE_NOT_FOUND( "The file '%s does not exist".printf( file ) );
            //gst-launch filesrc location=file.mp3 ! id3demux ! fakesink -t
            file_info = new HashTable<string,GLib.Value?>( str_hash, str_equal );
            file_info.insert( "filename", file );
            var pipe = new Pipeline( "file_pipeline" );

            var filesrc = Gst.ElementFactory.make( "filesrc", "src" );
            filesrc.set( "location", file );

            var id3demux = Gst.ElementFactory.make( "id3demux", "demux" );

            var fakesink = Gst.ElementFactory.make( "fakesink", "sink" );

            pipe.add_many( filesrc, id3demux, fakesink );
            filesrc.link( id3demux );
            id3demux.link( fakesink );
            id3demux.link( filesrc );
            fakesink.link( id3demux );

            var file_bus = pipe.get_bus();
            pipe.set_state( Gst.State.PLAYING );

            bool stop = false;

            while( ! stop )
            {
                if( ! file_bus.have_pending() )
                     stop = true;
                else
                {
                    var message = file_bus.pop();
                    switch( message.type )
                    {
                        case MessageType.TAG:
                            debug( "got Tag for %s", file );

                            Gst.TagList tag_list;
                            message.parse_tag ( out tag_list );
                            tag_list.foreach ( file_foreach_tag );
                            break;
                        case MessageType.EOS:
                            stop = true;
                            break;
                        case MessageType.ERROR:
                            GLib.Error err;
                            string debug;
                            message.parse_error( out err, out debug );
                            GLib.debug( "Message ERROR: %s %s", debug, err.message );
                            break;
                        default:
                            debug( "ignoring %s for %s", message.type.to_string(), file );
                            break;
                    }
                }
            }

            pipe.set_state( Gst.State.NULL );

            return file_info;
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
        }
        public void pause() throws MusicPlayerError, DBus.Error
        {
            this.audio_pipeline.set_state( Gst.State.PAUSED );
            this._state = FreeSmartphone.MusicPlayer.State.PAUSED;
            Source.remove( this.timeout_pos_handle );
        }
        public void stop() throws MusicPlayerError, DBus.Error
        {
            this.audio_pipeline.set_state( Gst.State.READY );
            this._state = FreeSmartphone.MusicPlayer.State.STOPPED;
            Source.remove( this.timeout_pos_handle );
        }
        public void previous() throws MusicPlayerError, DBus.Error
        {
            if( current_playlist == null )
                 throw new MusicPlayerError.NO_PLAYLIST_SELECTED( "No Playlist Selected" );
            var playlist = playlists.lookup( current_playlist );
            try
            {
                this.current_song = playlist.get_previous();
            }
            catch (PlaylistError e)
            {
                 throw new MusicPlayerError.PLAYLIST_OUT_OF_FILES( "Playlist %s has no more elements".printf(this.current_playlist));
            }
            play();
        }
        public void next() throws MusicPlayerError, DBus.Error
        {
            if( current_playlist == null )
                 throw new MusicPlayerError.PLAYLIST_OUT_OF_FILES( "No Playlist Selected" );
            var playlist = playlists.lookup( current_playlist );
            try
            {
                this.current_song = playlist.get_next();
            }
            catch (PlaylistError e)
            {
                 throw new MusicPlayerError.PLAYLIST_OUT_OF_FILES( "Playlist %s has no more elements".printf(this.current_playlist));
            }
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
            debug( "Jump to position: %ll", ((int64)pos) * 1000000000LL / Config.precision );
            playbin.seek_simple( Gst.Format.TIME, Gst.SeekFlags.NONE, ((int64)pos) * 1000000000 / Config.precision );
        }
        public ObjectPath[] get_playlists() throws MusicPlayerError, DBus.Error
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
            if( current_playlist == null )
                 throw new MusicPlayerError.NO_PLAYLIST_SELECTED( "No current playlist" );
            return current_playlist;
        }
        public void set_current_playlist( ObjectPath list ) throws MusicPlayerError, DBus.Error
        {
            var playlist = playlists.lookup( list );
            if( playlist == null )
                 throw new MusicPlayerError.UNKNOWN_PLAYLIST( "Playlist not found for %s".printf( list.rchr( list.len(),'/' ).next_char() ) );
            current_playlist = list;
        }
        public void delete_playlist( ObjectPath list ) throws MusicPlayerError, DBus.Error
        {
            var the_list = playlists.lookup( list );
            the_list.delete_files();
            playlists.remove( list );
            playlist_removed( list );
            debug( " deleting playlist refcount: %u", the_list.ref_count );
            the_list = null;
            
        }
        public ObjectPath new_playlist( string name ) throws MusicPlayerError, DBus.Error
        {
            var list = new Playlist( name, key_file );
            return add_playlist( name, list );
        }
        public ObjectPath add_playlist( string name, Playlist pl ) throws MusicPlayerError, DBus.Error
        {
            var obj_path = new ObjectPath(playlist_path + name);
            playlists.insert( obj_path, pl );
            playlist_added( obj_path );
            this.conn.register_object( playlist_path + name, pl );
            return obj_path;
        }
        public string[] search( string query ) throws MusicPlayerError, DBus.Error
        {
            return new string[0];
        }
        public int get_volume() throws DBus.Error
        {
            double ret = 0;
            playbin.get( "volume", out ret );
            debug("Volume: %lf", ret );
            return (int)( ret * 100.0 );
        }
        public void set_volume( int vol ) throws MusicPlayerError, DBus.Error
        {
            if( vol > 100 )
                 vol = 100;
            else if( vol < 0 )
                 vol = 0;
            playbin.set( "volume", (double)( vol/100.0 ) );
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
        private void file_foreach_tag (Gst.TagList list, string tag)
        {
            Gst.Value val;
            Gst.TagList.copy_value( out val, list, tag );
            debug( "new file tag: %s", tag );
            if( ! val.holds( typeof( Gst.Buffer ) ) && ! val.holds( typeof( Gst.Date ) ) )
                file_info.insert( tag, val );
        }
    }
}
