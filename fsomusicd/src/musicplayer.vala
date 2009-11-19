/* 
 * File Name: musicplayer.vala
 * Creation Date: 23-08-2009
 * Last Modified: 19-11-2009 21:52:16
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
using FreeSmartphone;
using Gee;

namespace FsoMusic
{
    public class MusicPlayer: FsoFramework.AbstractObject , FreeSmartphone.MusicPlayer
    {
        private int _wait_counter = 0;
        //Workaround to detect dec/inc. Is it possible to do this another way?
        private bool waiting = false;
        private int wait_counter{ default=0; get{return _wait_counter;}
            set{
                if( value < 0 )
                    logger.error( @"someone tried to set wait_counter to: $value < 0 waiting $waiting" );
                else
                {
                    logger.info( @"Set wait_counter: $wait_counter -> $value wating: $waiting" );
                    _wait_counter = value;
                    if( _wait_counter == 1 && ! waiting )
                    {
                        waiting = true;
                        if( cur_state == FreeSmartphone.MusicPlayerState.PLAYING )
                             was_playing = true;
                        else
                             was_playing = false;
                        logger.info( @"Restart playing: $was_playing" );
                        pause();
                    }
                    else if( _wait_counter == 0 && waiting )
                    {
                        waiting = false;
                        if( was_playing )
                            play();
                        logger.info( @"Pausing play: $was_playing" );
                    }
                }
            }
        }
        private bool was_playing = false;

        private unowned KeyFile key_file;
        private HashTable<string,string> audio_codecs;
        private HashTable<string,string> audio_srcs;
        private static string element_tail = "volume name=volume ! alsasink" ;
        private string current_song
        {
            get { return _current_song; }
            set
            {
                logger.debug( @"current song: $value" );
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
                var playlist = playlists.lookup( value );
                if( playlist != null )
                {
                    try
                    {
                        current_song = playlist.get_current_file();
                    }
                    catch (MusicPlayerPlaylistError e)
                    {
                        logger.debug( @"Get current song for $value: $(e.message)" );
                    }
                    _current_playlist = value;
                    logger.debug( @"new CurrentPlaylist: $value" );
                }
                else
                     logger.error( @"Cannot find a Playlist for: $value" );
            }
        }
        private ObjectPath _current_playlist;
        private Gst.Pipeline audio_pipeline;
        private Gst.Bus audio_bus;
        private Gst.Element volume;
        private Gst.Element core_stream;
        private Gst.Element source;
        //Save some time to avoid recreating of the Pipeline
        private string last_extension;
        private string last_protcol;
        private MusicPlayerState cur_state = FreeSmartphone.MusicPlayerState.STOPPED;
        private MusicPlayerState _state { 
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

        private int current_volume = 100;


        public MusicPlayer( KeyFile kf )
        {
            this.key_file = kf;

            var playlist_dir = Config.get_playlist_dir();
            try
            {
                foreach( var group in kf.get_groups() )
                {
                    if( group != Config.MUSIC_PLAYER_GROUP )
                    {
                        logger.debug( @"Try open playlist from '$group'" );
                        var pl = new Playlist( group, key_file, this );
                        add_playlist( group, pl );
                    }
                }
            }
            catch (GLib.Error e)
            {
                logger.debug( @"Open config directory $playlist_dir for playlist: $(e.message)" );
            }
        }
        construct
        {
            playlists = new HashTable<ObjectPath,Playlist>( str_hash, str_equal );
            audio_pipeline = null;
            last_extension = null;
            last_protcol = null;
            audio_codecs = new HashTable<string,string>(str_hash, str_equal);
            audio_srcs = new HashTable<string,string>(str_hash, str_equal);
            setup_audio_elements();
            setup_source_elements();
        }
        ~MusicPlayer()
        {
            save();
            audio_pipeline.set_state( Gst.State.NULL );
        }
        //
        // org.freesmartphone.MusicPlayer
        //
        public async HashTable<string,GLib.Value?> get_info_for_file( string file ) throws MusicPlayerError, DBus.Error
        {
            if( ! FileUtils.test( file, FileTest.EXISTS ) )
                 throw new MusicPlayerError.FILE_NOT_FOUND( @"The file $file does not exist" );
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
                            logger.debug( @"Parsing file tags for $file failed: $(err.message)." );
                            stop = true;
                            break;
                        default:
                            logger.info( @"Ignoring $(message.type) for $file" );
                            break;
                    }
                }
            }

            pipe.set_state( Gst.State.NULL );

            return file_info;
        }
        public async HashTable<string,GLib.Value?> get_playing_info() throws MusicPlayerError, DBus.Error
        {
            return this.cur_song_info;
        }
        public async string get_playing() throws MusicPlayerError, DBus.Error
        {
            if( current_song == null )
                 throw new MusicPlayerError.NO_FILE_SELECTED( "No file selected" );
            return current_song;
        }
        public async void set_playing( string file ) throws MusicPlayerError, DBus.Error
        {
            string ext = file.rchr( file.len(), '.' );
            string protocol = get_protocol_for_uri( file );
            if( last_extension != null && last_extension == ext && last_protcol == protocol )
            {
                audio_pipeline.set_state( Gst.State.NULL );
                var src = audio_pipeline.get_by_name( "source" );
                src.set( "location", file );
            }
            else
            {
                if( audio_pipeline != null )
                    audio_pipeline.set_state( Gst.State.NULL );

                var srcs = audio_srcs.lookup( protocol );
                if( srcs == null )
                     throw new MusicPlayerError.PROTOCOL_NOT_SUPPORTED( "Can't open %s".printf( file ) );

                var codec = audio_codecs.lookup( ext );
                if( codec == null )
                     throw new MusicPlayerError.FILETYPE_NOT_SUPPORTED( "Can't open %s".printf( file ) );
                var el = "".concat( srcs, " ! ",codec, " ! ", element_tail );


                logger.debug( @"Elements: \"$el\" for $file" );

                try
                {
                    var element = parse_launch( el );
                    audio_pipeline = element as Pipeline;
                    volume = audio_pipeline.get_by_name( "volume" );
                    set_volume( current_volume );
                    core_stream = audio_pipeline.get_by_name( "core" );
                    source = audio_pipeline.get_by_name( "source" );
                    source.set( "location", file );
                    audio_bus = audio_pipeline.get_bus();
                    audio_bus.add_watch( bus_callback );
                    last_extension = ext;
                    last_protcol = protocol;
                    Source.remove( timeout_pos_handle );
                    this.audio_pipeline.set_state( Gst.State.READY );
                    this._state = FreeSmartphone.MusicPlayerState.STOPPED;

                    this.cur_song_info = new HashTable<string,GLib.Value?>( str_hash, str_equal );
                    this.cur_song_info.insert( "filename", file );
                    playing_changed( file );
                }
                catch (GLib.Error e)
                {
                    logger.error( @"Parsing arguments: \"$(el)\" $(e.message)" );
                }
            }
        }
        public async void play() throws MusicPlayerError, DBus.Error
        {
            if( ! waiting )
            {
                if( audio_pipeline == null )
                     throw new FreeSmartphone.MusicPlayerError.NO_FILE_SELECTED( "No file selected" );
                this.audio_pipeline.set_state( Gst.State.PLAYING );
                this._state = FreeSmartphone.MusicPlayerState.PLAYING;
                timeout_pos_handle = Timeout.add( Config.poll_timeout, position_timeout );
            }
            else
                 logger.info( @"Reject playing, because we are waiting for some system events" );
        }
        public async void pause() throws MusicPlayerError, DBus.Error
        {
            if( audio_pipeline == null )
                 throw new FreeSmartphone.MusicPlayerError.NO_FILE_SELECTED( "No file selected" );
            this.audio_pipeline.set_state( Gst.State.PAUSED );
            this._state = FreeSmartphone.MusicPlayerState.PAUSED;
            Source.remove( this.timeout_pos_handle );
        }
        public async void stop() throws MusicPlayerError, DBus.Error
        {
            this.audio_pipeline.set_state( Gst.State.READY );
            this._state = FreeSmartphone.MusicPlayerState.STOPPED;
            Source.remove( this.timeout_pos_handle );
        }
        public async void previous() throws MusicPlayerError, DBus.Error
        {
            if( current_playlist == null )
                 throw new MusicPlayerError.NO_PLAYLIST_SELECTED( "No Playlist Selected" );
            var playlist = playlists.lookup( current_playlist );
            try
            {
                this.current_song = playlist.get_previous();
            }
            catch (MusicPlayerPlaylistError e)
            {
                 throw new MusicPlayerError.PLAYLIST_OUT_OF_FILES( "Playlist %s has no more elements".printf(this.current_playlist));
            }
            play();
        }
        public async void next() throws MusicPlayerError, DBus.Error
        {
            if( current_playlist == null )
                 throw new MusicPlayerError.PLAYLIST_OUT_OF_FILES( "No Playlist Selected" );
            var playlist = playlists.lookup( current_playlist );
            try
            {
                this.current_song = playlist.get_next();
            }
            catch (MusicPlayerPlaylistError e)
            {
                 throw new MusicPlayerError.PLAYLIST_OUT_OF_FILES( "Playlist %s has no more elements".printf(this.current_playlist));
            }
            play();
        }
        public async void seek_forward( int step ) throws MusicPlayerError, DBus.Error
        {
            jump( current_position + step );
        }
        public async void seek_backward( int step ) throws MusicPlayerError, DBus.Error
        {
            jump( current_position - step );
        }
        public async void jump( int pos ) throws MusicPlayerError, DBus.Error
        {
            audio_pipeline.seek_simple( Gst.Format.TIME, Gst.SeekFlags.NONE, ((int64)pos) * 1000000000 / Config.precision );
        }
        public async ObjectPath[] get_playlists() throws MusicPlayerError, DBus.Error
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
        public async ObjectPath get_current_playlist() throws MusicPlayerError, DBus.Error
        {
            if( current_playlist == null )
                 throw new MusicPlayerError.NO_PLAYLIST_SELECTED( "No current playlist" );
            return current_playlist;
        }
        public async void set_current_playlist( ObjectPath list ) throws MusicPlayerError, DBus.Error
        {
            var playlist = playlists.lookup( list );
            if( playlist == null )
                 throw new MusicPlayerError.UNKNOWN_PLAYLIST( "Playlist not found for %s".printf( list.rchr( list.len(),'/' ).next_char() ) );
            current_playlist = list;
        }
        public async void delete_playlist( ObjectPath list ) throws MusicPlayerError, DBus.Error
        {
            var the_list = playlists.lookup( list );
            the_list.delete_files();
            playlists.remove( list );
            playlist_removed( list );
            the_list = null;
            
        }
        public async ObjectPath new_playlist( string name ) throws MusicPlayerError, DBus.Error
        {
            var list = new Playlist( name, key_file, this );
            return add_playlist( name, list );
        }
        public ObjectPath add_playlist( string name, Playlist pl ) throws MusicPlayerError, DBus.Error
        {
            var obj_path = generate_path_for_playlist( name );
            var tmpobj = playlists.lookup( obj_path );
            if( tmpobj != null )
                 return obj_path;
            playlists.insert( obj_path, pl );
            playlist_added( obj_path );
            subsystem.registerServiceObject( FsoFramework.MusicPlayer.ServiceDBusName,
                                              obj_path, pl );
            return obj_path;
        }
        public string[] search( string query ) throws MusicPlayerError, DBus.Error
        {
            return new string[0];
        }
        public async int get_volume() throws DBus.Error
        {
            Gst.Value ret = Gst.Value();
            ret.init( typeof( double ) );
            Gst.ChildProxy.get_property( volume, "volume", out ret );
            return (int)( ret.get_double() * 100.0 );
        }
        public async void set_volume( int vol ) throws MusicPlayerError, DBus.Error
        {
            if( vol > 1000 )
                 vol = 1000;
            else if( vol < 0 )
                 vol = 0;
            Gst.ChildProxy.set( volume, "volume", (double)( vol / 100.0 ) );
            current_volume = vol;
        }

        public async void push_pause()
        {
            wait_counter ++;
            logger.info( @"push_pause: $wait_counter" );
        }
        public async void pop_pause()
        {
            wait_counter --;
            logger.info( @"pop_pause: $wait_counter" );
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
                    _state = FreeSmartphone.MusicPlayerState.STOPPED;
                    break;
                case Gst.State.PAUSED:
                    _state = FreeSmartphone.MusicPlayerState.PAUSED;
                    break;
                case Gst.State.PLAYING:
                    _state = FreeSmartphone.MusicPlayerState.PLAYING;
                    break;
                default:
                    break;
            }
        }
        public void save()
        {
            logger.debug( "Saving MusicPlayer" );
            var song = this.current_song == null ? "": this.current_song;
            var list = this.current_playlist == null ? "" : this.current_playlist;
            key_file.set_string( Config.MUSIC_PLAYER_GROUP, Config.LAST_PLAYED, song );
            key_file.set_string( Config.MUSIC_PLAYER_GROUP, Config.LAST_PLAYLIST, list );

            foreach( var k in playlists.get_values() )
            { 
                k.save();
            }
            logger.info( @"saving config to $(Config.get_config_path())" );
            save_keyfile_to_file( key_file, Config.get_config_path() );
        }
        //
        // private methods
        //
        private void setup_audio_elements()
        {
            register_element( "mad name=core", ".mp3", audio_codecs );
            if( ! register_element( "oggdemux ! ivorbisdec ! name=core ! audioconvert", ".ogg", audio_codecs ) )
                 register_element( "oggdemux ! vorbisdec name=core ! audioconvert", ".ogg", audio_codecs );
            register_element( "flacdec name=core ! audioconvert", ".flac", audio_codecs );
            register_element( "waveparse name=core", ".wav", audio_codecs );
            register_element( "siddec name=core" , ".sid", audio_codecs );
            register_element( "modplug name=core", ".mod", audio_codecs );
        }
        private void setup_source_elements()
        {
            register_element( "filesrc name=source", "", audio_srcs );
            register_element( "filesrc name=source", "file" , audio_srcs );
            if( ! register_element( "souphttpsrc name=source", "http", audio_srcs ) )
                register_element( "neonhttpsrc name=source", "http", audio_srcs );
            register_element( "mmssrc name=source", "mms" , audio_srcs );
        }
        private bool register_element( string elements, string extension, HashTable<string,string> to )
        {
            to.insert( extension, elements );
            debug( @"Registered audio elements \"$elements\" for $extension" );
            return true;
        }
        private string get_protocol_for_uri( string uri )
        {
            if( uri.has_prefix( "/" ) )
                 return "file";
            string prefix = uri.split( ":", 2 )[0];
            return prefix;
        }

        private DBus.ObjectPath generate_path_for_playlist( string name )
        {
            DBus.ObjectPath ret = null;
            try
            {
                var regex = new Regex( "[^[:alnum:]_]+" );
                var tmp = regex.replace( name, name.len(), 0, "_" );
                ret = new DBus.ObjectPath ( FsoFramework.MusicPlayer.PlaylistServicePathPrefix + "/" + tmp );
            }
            catch( RegexError e )
            {
                logger.error( @"Replacing $name for ObjectPath: $(e.message)" );
            }
            return ret;
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
                    logger.error( "Message: $debug $err" );
                    break;
                case MessageType.WARNING:
                    GLib.Error err;
                    string debug;
                    message.parse_warning( out err, out debug );
                    logger.warning( "Message: $debug $err" );
                    break;
                case MessageType.INFO:
                    GLib.Error err;
                    string debug;
                    message.parse_info( out err, out debug );
                    logger.info( "Message: $debug $err" );
                    break;
                case MessageType.EOS:
                    logger.info("End of stream");
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
                case MessageType.BUFFERING:
                    this._state = FreeSmartphone.MusicPlayerState.BUFFERING;
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
            if( core_stream.query_position( ref fmt, out cur ) )
            {
                current_position = (int)(cur * Config.precision / 1000000000 );
            }
            else
            {
                logger.error("Get position");
            }
            //Call me again
            return true;
        }
        private void file_foreach_tag (Gst.TagList list, string tag)
        {
            Gst.Value val;
            Gst.TagList.copy_value( out val, list, tag );
            if( ! val.holds( typeof( Gst.Buffer ) ) && ! val.holds( typeof( Gst.Date ) ) )
                file_info.insert( tag, val );
        }
        //
        // FsoFramework.AbstractObject
        //
        public override string repr()
        {
            return @"<$(this.get_type().name())>";
        }
        //
        // public methods
        //

        public async void jump_to_file_in_playlist( Playlist pl )
        {
            string name = null;
            try
            {
                name = yield pl.get_name();
            }
            catch (GLib.Error e)
            {
                logger.error( @"Lookup name for JumpTo: $(e.message)" );
                return;
            }
            var objpath = generate_path_for_playlist( name );
            current_playlist = objpath;
            try
            {
                current_song = pl.get_current_file();

            }
            catch (MusicPlayerPlaylistError mppe)
            {
                logger.debug( @"Tried to jump into playlist '$name': $(mppe.message)" );
            }
        }

        //
        // Helpers
        //
        public static void save_keyfile_to_file( GLib.KeyFile kf, string file )
        {
            var f = FileStream.open( file, "w" );
            if( f == null )
                 FsoFramework.Logger.defaultLogger().error( @"Cannot open $file: $(strerror(GLib.errno))");
            else
            {
                string data = kf.to_data();
                FsoFramework.Logger.defaultLogger().info( @"Saving KeyFile to $file" );
                f.puts(data);
            }
        }
    }
}
