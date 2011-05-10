/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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

namespace FsoFramework.FileSystem
{
    public class Path : GLib.Object
    {
        public string path { get; private set; }

        public Path( string path )
        {
            this.path = path;
        }

        public bool is_absolute()
        {
            return GLib.Path.is_absolute( this.path );
        }

        public bool is_mount_point()
        {
            Posix.Stat a, b;

            string parent_path = GLib.Path.get_dirname( path );

            if ( Posix.lstat( path, out a ) < 0 )
                return false;
            if ( Posix.lstat( parent_path, out b) < 0 )
                return false;

            return a.st_dev != b.st_dev;
        }
    }
}
