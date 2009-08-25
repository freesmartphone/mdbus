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
        private int position;
        private static string[] extensions = { ".mp3", ".ogg", ".flac" };

        public Playlist( string name, KeyFile kf )
        {
            this.key_file = kf;
            this._name = name;
        }
        public Playlist.from_dir( string name, KeyFile kf, string dir )
        {
            this( name, kf );
            insert_dir( 0, dir, true );
        }
        construct 
        {
            files = new List<string>();
            this.position = 0;
        }
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
            var ext = file.rchr( file.len(), '.' ).down();
            bool supported = false;
            foreach( var e in extensions )
            {
                if( ext == e )
                {
                    supported = true;
                    break;
                }
            }
            if( ! supported )
                 throw new PlaylistError.FILETYPE_NOT_SUPPORTED( "Filetype %s is not supported".printf( ext ));
            this.files.insert( file, position );
            file_added(position,file);
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
        }
        public string get_at_position( int position ) throws PlaylistError, DBus.Error
        {
            var f = this.files.nth_data( position );
            if( f == null)
                 throw new PlaylistError.OUT_OF_RANGE( "%u is out of range. List size: %u".printf(position,this.files.length()));
            return f;
        }
        public  void load_from_file( string file ) throws PlaylistError, DBus.Error
        {
            this.files = new List<string>();
            try
            {
                var fs = FileStream.open( file, "r" );
                if( fs == null )
                     throw new PlaylistError.FILE_NOT_FOUND( "Can't open file: %s".printf(file));
                while(!fs.eof())
                {
                    string? line = fs.read_line();
                    this.files.prepend( line );
                }
                this.files.reverse();
            }
            catch( FileError e )
            {
                debug("File error for %s: %s", file, e.message );
            }
        }
    }
}
