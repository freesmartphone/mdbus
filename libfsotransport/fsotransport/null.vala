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

//===========================================================================
public class FsoFramework.NullTransport : FsoFramework.BaseTransport
//===========================================================================
{
    public NullTransport( string name="null", uint speed=0, bool raw=true, bool hard=true )
    {
        base( name, speed, raw, true );
    }

    public override bool open()
    {
        return true;
    }

    public override bool isOpen()
    {
        return true;
    }

    public override string repr()
    {
        return "<>";
    }

    public override string getName()
    {
        return "null";
    }

    public override void close()
    {
    }

    public override int read( void* data, int len )
    {
        return len;
    }

    public override int write( void* data, int len )
    {
        return len;
    }

    public override int writeAndRead( void* wdata, int wlength, void* rdata, int rlength, int maxWait = 1000 )
    {
        return rlength;
    }

    public override int freeze()
    {
        return -1;
    }

    public override void thaw()
    {
    }
}
