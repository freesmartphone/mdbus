/*
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

using GLib;

public class FsoGsm.Channel : FsoGsm.AtCommandQueue
{
    protected string name;

    public Channel( string name, FsoFramework.Transport transport, FsoFramework.Parser parser )
    {
        base( transport, parser );
        this.name = name;
        theModem.registerChannel( name, this );

        theModem.signalStatusChanged += onModemStatusChanged;
    }

    public override string repr()
    {
        return "<Channel '%s'>".printf( name );
    }

    public void onModemStatusChanged( FsoGsm.Modem modem, int status )
    {
        if ( status == FsoGsm.Modem.Status.INITIALIZING )
        {
            var cmds = modem.commandSequence( "init" );
            foreach( var cmd in cmds )
            {
                debug( "sending cmd '%s'", cmd );
                enqueue( new NullAtCommand(), cmd );
            }
        }

    }
}

// vim:ts=4:sw=4:expandtab

