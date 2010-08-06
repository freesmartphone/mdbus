/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
using FsoGsm;

public class MsmChannel : MsmCommandQueue, FsoGsm.Channel
{
    public string name;
    private bool atChannelOpened;

    public MsmChannel( string name, FsoFramework.Transport transport )
    {
        base( transport );
        this.name = name;
        theModem.registerChannel( name, this );
        theModem.signalStatusChanged.connect( onModemStatusChanged );
    }

    public void injectResponse( string response )
    {
        assert_not_reached();
    }

    public async bool suspend()
    {
        return true;
    }

    public async bool resume()
    {
        return true;
    }

    public override async bool open()
    {
        // open transport
        assert( !transport.isOpen() );
        var opened = yield transport.openAsync();

        if ( !yield base.open() )
            return false;

        context.registerEventHandler( onMsmcommGotEvent );
        context.registerReadHandler( onMsmcommShouldRead );
        context.registerWriteHandler( onMsmcommShouldWrite );

        debug( "SENDING RESET COMMAND" );

        var cmd1 = new Msmcomm.Command.ChangeOperationMode();
        cmd1.setOperationMode( Msmcomm.OperationMode.RESET );
        unowned Msmcomm.Message response = yield enqueueAsync( (owned)cmd1 );

        // FIXME: Should send test alive command until first URC has been received

        debug( "OK; MSM CHANNEL OPENED" );

        return true;
    }

    public void onModemStatusChanged( Modem modem, Modem.Status status )
    {
    }
}

