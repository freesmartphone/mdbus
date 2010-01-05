/* 
 * File Name: playlist.vala
 * Creation Date: 23-08-2009
 * Last Modified: 05-01-2010 02:48:58
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
using FreeSmartphone;

namespace FsoMusic
{
    public class Playlist: FsoFramework.AbstractObject, MusicPlayerPlaylist
    {
        private unowned KeyFile key_file;
        private string _name;
        private List<string> files;
        private static string[] supported_extensions = { ".mp3", ".ogg", ".flac", ".wav", ".sid", ".mod" };
        private weak List<string> _current;
        private unowned MusicPlayer musicplayer;
        private weak List<string> current
        {
            get{ return _current; }
            set
            {
                if( _current != value )
                {
                    if( value != null && value.data != null )
                    {
                        _current = value;
                        playing( value.data );
                    }
                }
            }
        }
        private delegate string DoGetNext() throws MusicPlayerPlaylistError;
        private delegate string DoGetPrevious() throws MusicPlayerPlaylistError;

        private DoGetNext do_get_next;
        private DoGetPrevious do_get_previous;

        private MusicPlayerPlaylistMode _mode;
        public MusicPlayerPlaylistMode mode
        {
            get{ return _mode; }
            set
            {
                switch( value )
                {
                    case( MusicPlayerPlaylistMode.NORMAL ):
                        do_get_next = get_next_normal;
                        do_get_previous = get_previous_normal;
                        break;
                    case( MusicPlayerPlaylistMode.RANDOM ):
                        //Both would return a randome file
                        do_get_next = get_next_random;
                        do_get_previous = get_next_random;
                        break;
                    case( MusicPlayerPlaylistMode. ENDLESS ):
                        do_get_next = get_next_endless;
                        do_get_previous = get_previous_endless;
                        break;
                    default:
                        logger.error( @"Illegal Mode: $(FsoFramework.StringHandling.enumToString(typeof(MusicPlayerPlaylistMode), value))" );
                        break;
                }
                _mode = value;
                mode_changed( value );
            }
        }

        private int position;

        public Playlist( string name, KeyFile kf, MusicPlayer mp )
        {
            base();
            this.key_file = kf;
            this._name = name;
            musicplayer = mp;
            logger = FsoFramework.createLogger( FsoFramework.Utility.programName() + ".playlist" , @"$classname.$name" );
            logger.info( @"New Playlist named '$name'" );
            try
            {
                position = kf.get_integer( name, Config.LAST_PLAYED );
                load_from_uri( Path.build_filename( Config.get_playlist_dir(), name ) );
                _current = files.nth( position );
            }
            catch (GLib.Error e)
            {
                logger.error( @"Ignoring Error: $(e.message)" );
                position = 0;
            }
            try
            {
                mode = (MusicPlayerPlaylistMode)kf.get_integer( name, Config.PLAYLIST_MODE );
            }
            catch (GLib.Error e)
            {
                logger.error( @"Ignoring Error: $(e.message)" );
            }
            try
            {
                var playlist_path = kf.get_string( name, Config.PLAYLIST_PATH );
                logger.debug( @"Load from path: $playlist_path" );
                load_from_uri( playlist_path, (a,b) => { logger.info( @"finished loading files for $(this._name)" );} );
            }
            catch (GLib.Error e)
            {
                logger.error( @"Loading playlist: $(e.message)" );
            }
        }
        public Playlist.from_dir( string name, KeyFile kf, string dir, MusicPlayer mp )
        {
            this( name, kf, mp );
            //workaround for #147937
            var load_dir = dir;
            insert_dir( 0, dir, true, () =>{ logger.info( @"Load $load_dir for $(this._name) finished" );} );
            position = 0;
            current = files;
        }
        construct 
        {
            files = new List<string>();
            this.position = 0;
            _current = files;
            this.mode = MusicPlayerPlaylistMode.NORMAL;
        }
        //
        // org.freesmartphone.MusicPlayer.Playlist
        //
        public async int add( string file ) throws DBus.Error, MusicPlayerPlaylistError
        {
            int new_pos = (int)this.files.length();
            yield insert( new_pos, file );
            return new_pos;
        }
        public async string get_name() throws MusicPlayerPlaylistError, DBus.Error
        {
            return _name;
        }
        public async void change_name( string new_name ) throws MusicPlayerPlaylistError, DBus.Error
        {
            this._name = new_name;
            name( this._name );
        }
        public async string[] get_files() throws MusicPlayerPlaylistError, DBus.Error
        {
            string[] ret = new string[this.files.length()];
            int i = 0;
            foreach( string f in files )
            {
                ret[i++] = f;
            }
            return ret;
        }
        public async void set_mode( MusicPlayerPlaylistMode m )
        {
            mode = m;
        }
        public async MusicPlayerPlaylistMode get_mode()
        {
            return mode;
        }
        public async void insert( int position, string file ) throws MusicPlayerPlaylistError, DBus.Error
        {
            if( ! file_supported( file ) )
                 throw new MusicPlayerPlaylistError.FILETYPE_NOT_SUPPORTED( @"Filetype for $file is not supported" );
            this.files.insert( file, position );
            if( current == null )
                 current = files;
            file_added( position,file );
            if( position < this.position )
                 this.position++;
            logger.debug( "Inserted $file at $position" );
        }
        public async void insert_dir( int position, string dir, bool recursive ) throws MusicPlayerPlaylistError, DBus.Error
        {
            logger.debug( @"Insert $dir at $position. recursive: $recursive" );
            try
            {
                var curdir = File.new_for_path( dir );
                var iter = yield curdir.enumerate_children_async (FILE_ATTRIBUTE_STANDARD_NAME, 0, Priority.DEFAULT, null);
                while (true) 
                {
                    var files = yield iter.next_files_async (10, Priority.DEFAULT, null);
                    if (files == null) 
                            break;
                    foreach (var file in files) 
                    {
                        var full_path = Path.build_filename( dir, file.get_name() );
                        if( FileUtils.test( full_path, FileTest.IS_DIR ) )
                        {
                            if( recursive )
                                yield insert_dir( position, full_path, recursive );
                        }
                        else if( FileUtils.test( full_path, FileTest.EXISTS ) )
                        {
                            try
                            {
                                yield insert( position, full_path );
                                position ++;
                            }
                            catch (MusicPlayerPlaylistError mppe)
                            {
                                logger.debug( @"insert into Playlist: $(mppe.message)" );
                            }
                        }
                        else
                             throw new MusicPlayerPlaylistError.FILE_NOT_FOUND( @"Cannot find file $full_path" );
                    }
                }
                yield iter.close_async( Priority.DEFAULT, null );
            }
            catch ( GLib.Error e )
            {
                logger.debug( @"InserDir: $(e.message)" );
            }
        }

        public async void jump_to( int position ) throws MusicPlayerPlaylistError
        {
            if( files == null )
                 throw new MusicPlayerPlaylistError.EMPTY( "The playlist is empty" );
            unowned List<string> nth = files.nth( position );
            if( nth == null )
                 throw new MusicPlayerPlaylistError.OUT_OF_RANGE( @"$position is to big. Playlist size: $(files.length())" );
            current = nth;
            yield musicplayer.jump_to_file_in_playlist( this );
        }
        public async void remove( int position ) throws MusicPlayerPlaylistError
        {
            var f = files.nth_data( position );
            if( f != null )
            {
                this.files.remove( f );
            }
            else
                 throw new MusicPlayerPlaylistError.OUT_OF_RANGE( "%i is to big. Playlist size: %i", position, files.length());
            if( position < this.position)
                 this.position--;
        }
        public async string get_at_position( int position ) throws MusicPlayerPlaylistError, DBus.Error
        {
            if( position > files.length())
                 throw new MusicPlayerPlaylistError.OUT_OF_RANGE( "%u is out of range. List size: %u".printf(position,this.files.length()));
            var f = this.files.nth_data( position );
            return f;
        }
        public async void load_from_uri( string uri ) throws MusicPlayerPlaylistError, DBus.Error
        {
            try
            {
                var f = File.new_for_uri( uri );
                var in_stream = yield f.read_async( Priority.DEFAULT, null );
                var data_stream = new DataInputStream( in_stream ); 
                while( true )
                {
                    size_t len;
                    var line = yield data_stream.read_line_async( Priority.DEFAULT, null, out len );
                    if( line == null )
                         break;
                    if( len > 0 )
                         files.prepend( line );
                }
            }
            catch (GLib.Error e)
            {
                logger.error( @"LoadFromFile: $(e.message)" );
                throw new MusicPlayerPlaylistError.FILE_NOT_FOUND( "Can't open file: %s".printf(uri));
            }

            this.files.reverse();
        }
        //
        // None DBus methods
        //
        public void delete_files()
        {
            var playlist_path = Path.build_filename( Config.get_playlist_dir(), _name );
            FileUtils.remove( playlist_path ) ;
            try
            {
                key_file.remove_group( _name );
            }
            catch ( GLib.Error e )
            {
                logger.debug( @"Ignoring: $(e.message)" );
            }
        }
        public bool file_supported( string file )
        {
            var ext = file.rchr( file.len(), '.' ).down();
            foreach( var e in supported_extensions )
            {
                if( ext == e )
                {
                    return true;
                }
            }
            return false;
        }
        public void save()
        {
            logger.info( @"Saving Playlist $_name" );
            logger.info( "key_file: %p".printf( key_file ) );
            key_file.set_integer( _name, Config.LAST_PLAYED, position );
            key_file.set_integer( _name, Config.PLAYLIST_MODE, mode );
            key_file.set_string( _name, Config.PLAYLIST_NAME, _name );

            var playlist_path = Path.build_filename( Config.get_playlist_dir(), _name );
            key_file.set_string( _name, Config.PLAYLIST_PATH, playlist_path );

            logger.info( @"Saving $_name to $playlist_path" );
            var fs = FileStream.open( playlist_path, "w" );
            foreach( var file in files )
                    if( file != null )
                        fs.printf( "%s\n", file );
        }
        public string get_next() throws MusicPlayerPlaylistError
        {
            return this.do_get_next();
        }
        public string get_previous() throws MusicPlayerPlaylistError
        {
            return this.do_get_previous();
        }

        //
        // Private methods for different random modes
        //

        private string get_next_normal() throws MusicPlayerPlaylistError
        {
            if( this.files.length() == 0 )
                 throw new MusicPlayerPlaylistError.EMPTY( "No files in playlist" );
            if( this.current == null )
                 throw new MusicPlayerPlaylistError.NO_FILE_SELECTED( "No file selected" );
            if( this.current.next == null )
                 throw new MusicPlayerPlaylistError.OUT_OF_FILES( "No more file in the playlist" );
            this.current = this.current.next;
            position++;
            return this.current.data;
        }
        private string get_previous_normal() throws MusicPlayerPlaylistError
        {
            if( this.files.length() == 0 )
                 throw new MusicPlayerPlaylistError.EMPTY( "No files in playlist" );
            if( this.current == null )
                 throw new MusicPlayerPlaylistError.NO_FILE_SELECTED( "No file selected" );
            if( this.current.prev == null )
                 throw new MusicPlayerPlaylistError.OUT_OF_FILES( "No more file in the playlist" );
            this.current = this.current.prev;
            position--;
            return this.current.data;
        }
        private string get_next_endless() throws MusicPlayerPlaylistError
        {
            string result;
            result = get_next_normal();
            if( result == null )
            {
                this.current = this.files.first();
                this.position = 0;
                result = this.current.data;
            }
            return result;
        }
        private string get_previous_endless() throws MusicPlayerPlaylistError
        {
            string result = get_previous_normal();
            if( result == null )
            {
                this.current = this.files.last();
                this.position = (int)(this.files.length() - 1);
                result = this.current.data;
            }
            return result;
        }
        private string get_next_random() throws MusicPlayerPlaylistError
        {
            if( this.files.length() == 0 )
                 throw new MusicPlayerPlaylistError.EMPTY( "No files in playlist" );
            var rand = new Rand();
            uint nr = (uint) rand.int_range( 0, (int)this.files.length() - 1 );
            this.current = this.files.nth( nr );
            this.position = (int)nr;
            return this.current.data;
        }
        //
        // AbstractObject methods
        //
        public override string repr()
        {
            return "<%s>".printf( this.get_type().name() );
        }

        //
        // public methods
        //
        public string get_current_file() throws MusicPlayerPlaylistError
        {
            if( files.length() == 0 )
                 throw new MusicPlayerPlaylistError.EMPTY( "Playlist is empty" );
            return current.data;
        }
        
    }
}
