/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using GLib;

namespace FsoFramework
{

internal static SmartKeyFile _masterkeyfile = null;

public static SmartKeyFile MasterKeyFile()
{
    if ( _masterkeyfile == null )
    {
        _masterkeyfile = new SmartKeyFile();
        // first, try the user directory
        var try1 = "%s/.frameworkd.conf".printf( Environment.get_home_dir() );
        var try2 = "/etc/frameworkd.conf";
        if ( !_masterkeyfile.loadFromFile( try1 ) && !_masterkeyfile.loadFromFile( try2 ) )
        {
            warning( "could not load %s nor %s", try1, try2 );
        }
    }
    return _masterkeyfile;
}

}
