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

/**
 * @class FsoFramework.DelegateTransport
 *
 * A delegate transport delegates all its operations to delegates.
 */
public class FsoFramework.DelegateTransport : FsoFramework.BaseTransport
{
    TransportDataFunc          writefuncd;
    TransportDataFunc          readfuncd;
    TransportFunc              hupfuncd;
    TransportBoolFunc          openfuncd;
    TransportFunc              closefuncd;
    TransportIntFunc           freezefuncd;
    TransportFunc              thawfuncd;

    public DelegateTransport( TransportDataFunc writefunc,
                              TransportDataFunc readfunc,
                              TransportFunc hupfunc,
                              TransportBoolFunc openfunc,
                              TransportFunc closefunc,
                              TransportIntFunc freezefunc,
                              TransportFunc thawfunc )
    {
        base( "TransportDelegate" );

        this.writefuncd = writefunc;
        this.readfuncd = readfunc;
        this.hupfuncd = hupfunc;
        this.openfuncd = openfunc;
        this.closefuncd = closefunc;
        this.freezefuncd = freezefunc;
        this.thawfuncd = thawfunc;
    }

    public override bool open()
    {
        return this.openfuncd( this );
    }

    public override bool isOpen()
    {
        return true;
    }

    public override int write( void* data, int length )
    {
        return this.writefuncd( data, length, this );
    }

    public override int read( void* data, int length )
    {
        return this.readfuncd( data, length, this );
    }

    public override int freeze()
    {
        return this.freezefuncd( this );
    }

    public override void thaw()
    {
        this.thawfuncd( this);
    }

    public override void close()
    {
        this.closefuncd( this );
    }

    public override void setBuffered( bool on )
    {
        // NOP for the delegate
    }

    public override int writeAndRead( void* wdata, int wlength, void* rdata, int rlength, int maxWait = 1000 )
    {
        assert_not_reached(); // NYI here
    }
}
