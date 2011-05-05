/**
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

/**
 * @class FsoFramework.OverlayFile
 **/
public class FsoFramework.OverlayFile : GLib.Object
{
    private string filename;

    public OverlayFile( string filename, string newcontent )
    {
        try
        {
            string contents;
            size_t length;
            GLib.FileUtils.get_contents( filename, out contents, out length );
            GLib.FileUtils.set_contents( filename + ".saved", contents, (ssize_t)length );
            GLib.FileUtils.set_contents( filename, newcontent, newcontent.length );
            this.filename = filename;
        }
        catch ( FileError e )
        {
            warning( @"Could not save $filename: $(strerror(errno))" );
        }
    }

    ~OverlayFile()
    {
        if ( filename != null )
        {
            try
            {
                string contents;
                size_t length;
                GLib.FileUtils.get_contents( filename + ".saved", out contents, out length );
                GLib.FileUtils.set_contents( filename, contents, (ssize_t)length );
                GLib.FileUtils.remove( filename + ".saved" );
            }
            catch ( FileError e )
            {
                warning( @"Could not restore $filename: $(strerror(errno))" );
            }
        }
    }
}

// vim:ts=4:sw=4:expandtab
