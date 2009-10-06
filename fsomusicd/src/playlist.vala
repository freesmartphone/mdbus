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
    public class Playlist: GLib.Object, IPlaylist
    {
        private unowned KeyFile key_file;
        private string _name;
        private List<string> files;
        private static string[] supported_extensions = { ".mp3", ".ogg", ".flac", ".wav", ".sid", ".mod" };
        private weak List<string> _current;
        private weak List<string> current
        {
            get{ return _current; }
            set
            {
                debug("value:%p", value );
                debug("value:%p", value.data);
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
        private delegate string DoGetNext() throws PlaylistError;
        private delegate string DoGetPrevious() throws PlaylistError;

        private DoGetNext do_get_next;
        private DoGetPrevious do_get_previous;

        private PlaylistMode _mode;
        public PlaylistMode mode
        {
            get{ return _mode; }
            set
            {
                switch( value )
                {
                    case( PlaylistMode.NORMAL ):
                        do_get_next = get_next_normal;
                        do_get_previous = get_previous_normal;
                        break;
                    case( PlaylistMode.RANDOM ):
                        //Both would return a randome file
                        do_get_next = get_next_random;
                        do_get_previous = get_next_random;
                        break;
                    case( PlaylistMode. ENDLESS ):
                        do_get_next = get_next_endless;
                        do_get_previous = get_previous_endless;
                        break;
                    default:
                        debug( "Illegal Mode: %i", value );
                        assert_not_reached();
                }
                _mode = value;
                mode_changed( value );
            }
        }

        private int position;

        public Playlist( string name, KeyFile kf )
        {
            this.key_file = kf;
            this._name = name;
            try
            {
                position = kf.get_integer( name, Config.LAST_PLAYED );
                load_from_file( Path.build_filename( Config.get_playlist_dir(), name ) );
                _current = files.nth( position );
            }
            catch (GLib.Error e)
            {
                debug( "Ignoring Error: %s", e.message );
                position = 0;
            }
            try
            {
                mode = (PlaylistMode)kf.get_integer( name, Config.PLAYLIST_MODE );
            }
            catch (GLib.Error e)
            {
                debug( "Ignoring Error: %s", e.message );
            }
        }
        public Playlist.from_dir( string name, KeyFile kf, string dir )
        {
            this( name, kf );
            try
            {
                insert_dir( 0, dir, true );
            }
            catch ( GLib.Error e )
            {
                debug( "Playlist.from_dir: %s", e.message );
            }
            position = 0;
            current = files;
        }
        construct 
        {
            files = new List<string>();
            this.position = 0;
            debug("playlist construct");
            _current = files;
            this.mode = PlaylistMode.NORMAL;
        }
        //
        // org.freesmartphone.MusicPlayer.Playlist
        //
        public string get_name() throws PlaylistError, DBus.Error
        {
            return _name;
        }
        public void change_name( string new_name ) throws PlaylistError, DBus.Error
        {
            this._name = new_name;
            name( this._name );
        }
        public string[] get_files() throws PlaylistError, DBus.Error
        {
            string[] ret = new string[this.files.length()];
            int i = 0;
            foreach( string f in files )
            {
                ret[i++] = f;
            }
            return ret;
        }
        public void set_mode( PlaylistMode m )
        {
            mode = m;
        }
        public PlaylistMode get_mode()
        {
            return mode;
        }
        public void insert( int position, string file ) throws PlaylistError, DBus.Error
        {
            debug("Adding %s to %s", file, _name );
            if( ! file_supported( file ) )
                 throw new PlaylistError.FILETYPE_NOT_SUPPORTED( "Filetype for %s is not supported".printf( file ));
            this.files.insert( file, position );
            file_added(position,file);
            if( position < this.position )
                 this.position++;
        }
        public void insert_dir( int position, string dir, bool recursive ) throws PlaylistError, DBus.Error
        {
            try
            {
                var curdir = GLib.Dir.open( dir, 0 );
                for( string file =  curdir.read_name(); file != null; file = curdir.read_name() )
                {
                    var full_path = Path.build_filename( dir, file );
                    if( FileUtils.test( full_path, FileTest.IS_DIR ) )
                    {
                        if( recursive )
                        {
                            insert_dir( position, full_path, recursive );
                        }
                    }
                    else if( FileUtils.test( full_path, FileTest.EXISTS ) )
                    {
                        try
                        {
                            insert( position, full_path );
                            position ++;
                        }
                        catch (PlaylistError e)
                        {
                            debug( "insert into Playlist: %s", e.message );
                        }
                    }
                    else
                         throw new PlaylistError.FILE_NOT_FOUND( "Can't find file %s", full_path );
                }
            }
            catch ( GLib.FileError fe )
            {
                debug("File Error: %s", fe.message );
            }
        }
        public void remove( int position ) throws PlaylistError
        {
            var f = files.nth_data( position );
            if( f != null )
            {
                this.files.remove( f );
            }
            else
                 throw new PlaylistError.OUT_OF_RANGE( "%i is to big. Playlist size: %i", position, files.length());
            if( position < this.position)
                 this.position--;
        }
        public string get_at_position( int position ) throws PlaylistError, DBus.Error
        {
            if( position > files.length())
                 throw new PlaylistError.OUT_OF_RANGE( "%u is out of range. List size: %u".printf(position,this.files.length()));
            var f = this.files.nth_data( position );
            return f;
        }
        public  void load_from_file( string file ) throws PlaylistError, DBus.Error
        {
            debug( "%s: %s", Log.METHOD, file );
            this.files = new List<string>();
            var fs = FileStream.open( file, "r" );
            if( fs == null )
                 throw new PlaylistError.FILE_NOT_FOUND( "Can't open file: %s".printf(file));
            while(!fs.eof())
            {
                string? line = fs.read_line();
                if( line != null && line.len() > 0 )
                    this.files.prepend( line );
            }
            this.files.reverse();
            debug("New Playlist.length: %ll", file.len());
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
                debug( "Ignoring: %s", e.message );
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
            key_file.set_integer( _name, Config.LAST_PLAYED, position );
            key_file.set_integer( _name, Config.PLAYLIST_MODE, mode );

            var playlist_path = Path.build_filename( Config.get_playlist_dir(), _name );
            var fs = FileStream.open( playlist_path, "w+" );
            foreach( var file in files )
                    if( file != null )
                        fs.printf( "%s\n", file );
        }
        public string get_next() throws PlaylistError
        {
            debug("this: %p", this );
            debug("delegate: %p", (void*)this.do_get_next );
            debug("Mode: %i", _mode);
            return this.do_get_next();
        }
        public string get_previous() throws PlaylistError
        {
            return this.do_get_previous();
        }

        //
        // Private methods for differen random modes
        //

        private string get_next_normal() throws PlaylistError
        {
            if( this.files.length() == 0 )
                 throw new PlaylistError.EMPTY( "No files in playlist" );
            if( this.current == null )
                 throw new PlaylistError.NO_FILE_SELECTED( "No file selected" );
            if( this.current.next == null )
                 throw new PlaylistError.OUT_OF_FILES( "No more file in the playlist" );
            this.current = this.current.next;
            position++;
            return this.current.data;
        }
        private string get_previous_normal() throws PlaylistError
        {
            if( this.files.length() == 0 )
                 throw new PlaylistError.EMPTY( "No files in playlist" );
            if( this.current == null )
                 throw new PlaylistError.NO_FILE_SELECTED( "No file selected" );
            if( this.current.prev == null )
                 throw new PlaylistError.OUT_OF_FILES( "No more file in the playlist" );
            this.current = this.current.prev;
            position--;
            return this.current.data;
        }
        private string get_next_endless() throws PlaylistError
        {
            debug( "next_endless: %i next: %p", position, this.current.next );
            debug( "length: %u", this.files.length() );
            foreach( var d in files )
            {
                debug("file: %p", d );
            }
            string result;
            try
            {
                result = get_next_normal();
            }
            catch ( PlaylistError.OUT_OF_FILES e )
            {
                debug( "Playlist get first" );
                this.current = this.files.first();
                this.position = 0;
                result = this.current.data;
            }
            return result;
        }
        private string get_previous_endless() throws PlaylistError
        {
            debug( "prev_endless: %i prev: %p", position, this.current.prev );
            string result;
            try
            {
                result = get_previous_normal();
            }
            catch ( PlaylistError.OUT_OF_FILES e )
            {
                debug( "Playlist get last" );
                this.current = this.files.last();
                this.position = (int)(this.files.length() - 1);
                result = this.current.data;
            }
            return result;
        }
        private string get_next_random() throws PlaylistError
        {
            if( this.files.length() == 0 )
                 throw new PlaylistError.EMPTY( "No files in playlist" );
            if( this.current == null )
                 throw new PlaylistError.NO_FILE_SELECTED( "No file selected" );
            var rand = new Rand();
            uint nr = (uint) rand.int_range( 0, (int)this.files.length() - 1 );
            this.current = this.files.nth( nr );
            this.position = (int)nr;
            debug( "random nr: %i %s", this.position, this.current.data );
            return this.current.data;
        }
    }
}
