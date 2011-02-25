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
 **/

/**
 * @class FsoFramework.FdPipe
 **/
public class FsoFramework.FdPipe : GLib.Object
{
    private const uint BUFSIZE = 512;
    private char[] buffer;

    private GLib.IOChannel source;
    private GLib.IOChannel destout;

    private uint sourceWatch;
    private uint destoutWatch;

    private int sfd;
    private int dinfd;
    private int doutfd;

    private bool onAction( GLib.IOChannel source, GLib.IOCondition condition )
    {
        if ( ( condition & GLib.IOCondition.HUP ) == GLib.IOCondition.HUP )
        {
            error( @"AutoPipe: HUP from source fd $(source.unix_get_fd()). Stopping." );
            return false;
        }

        if ( ( condition & GLib.IOCondition.IN ) == GLib.IOCondition.IN )
        {
            var readfd = source.unix_get_fd();
            var writefd = readfd == sfd ? dinfd : sfd;

            var bread = Posix.read( readfd, buffer, BUFSIZE );
            assert( bread > 0 );
            var bwritten = Posix.write( writefd, buffer, bread );
            assert( bwritten == bread );
        }
        else
        {
            error( "AutoPipe: Unknown IOCondition. Stopping." );
            return false;
        }
        return true;
    }

    //
    // public API
    //

    public FdPipe( int s, int din, int dout )
    {
        sfd = s;
        dinfd = din;
        doutfd = dout;

        source = new GLib.IOChannel.unix_new( s );
        destout = new GLib.IOChannel.unix_new( dout );

        sourceWatch = source.add_watch( GLib.IOCondition.IN | GLib.IOCondition.HUP, onAction );
        destoutWatch = destout.add_watch( GLib.IOCondition.IN | GLib.IOCondition.HUP, onAction );

        buffer = new char[BUFSIZE];
    }

    ~FdPipe()
    {
        Source.remove( sourceWatch );
        Source.remove( destoutWatch );
    }
}
