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
        private static string[] extensions = { ".mp3", ".ogg", ".flac" };
        private weak List<string> _current;
        private weak List<string> current
        {
            get{ return _current; }
            set
            {
                if( _current != value )
                {
                    _current = value;
                    if( value != null )
                         playing( value.data );
                }
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
                current = files.nth( position );
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
            current = files;
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
                if( line != null && line.len() > 0 );
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
            foreach( var e in extensions )
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

            var playlist_path = Path.build_filename( Config.get_playlist_dir(), _name );
            var fs = FileStream.open( playlist_path, "w+" );
            foreach( var file in files )
                    if( file != null )
                        fs.printf( "%s\n", file );
        }
        public string get_next() throws PlaylistError
        {
            if( this.files.length() == 0 )
                 throw new PlaylistError.EMPTY( "No files in playlist" );
            if( this.current == null )
                 throw new PlaylistError.NO_FILE_SELECTED( "No file selected" );
            this.current = this.current.next;
            if( this.current == null )
                 throw new PlaylistError.OUT_OF_FILES( "No more file in the playlist" );
            position++;
            return this.current.data;
        }
        public string get_previous() throws PlaylistError
        {
            if( this.files.length() == 0 )
                 throw new PlaylistError.EMPTY( "No files in playlist" );
            if( this.current == null )
                 throw new PlaylistError.NO_FILE_SELECTED( "No file selected" );
            this.current = this.current.prev;
            if( this.current == null )
                 throw new PlaylistError.OUT_OF_FILES( "No more file in the playlist" );
            position--;
            return this.current.data;
        }
    }
}
