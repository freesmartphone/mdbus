/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 * Copyright (C) 2010 Denis 'GNUtoo' Carikli <GNUtoo@no-log.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;
using FsoGsm;

public class IsiChannel : FsoGsm.Channel, FsoFramework.AbstractCommandQueue
{
    private NokiaIsi.IsiUnsolicitedHandler unsolicitedHandler;

    public string name;

    public delegate void UnsolicitedHandler( string prefix, string response, string? pdu = null );

    private bool _is_initialized;

    private void onModemStatusChanged( FsoGsm.Modem modem, FsoGsm.Modem.Status status )
    {
        switch ( status )
        {
            case FsoGsm.Modem.Status.INITIALIZING:
                initialize();
                break;
            case FsoGsm.Modem.Status.ALIVE_SIM_READY:
                poweron();
                break;
            case FsoGsm.Modem.Status.CLOSING:
                shutdown();
                break;
            default:
                break;
        }
    }

    public override async bool open()
    {
        return yield transport.openAsync();
    }

    protected override void onReadFromTransport( FsoFramework.Transport t )
    {
        assert_not_reached();
    }

    //
    // public API
    //
    public IsiChannel( string name, IsiTransport transport )
    {
        base( transport );
        this.name = name;
        theModem.registerChannel( name, this );
        theModem.signalStatusChanged.connect( onModemStatusChanged );
    }

    public async void poweron()
    {
        unsolicitedHandler = new NokiaIsi.IsiUnsolicitedHandler();
        yield NokiaIsi.isimodem.poweron();
    }

    public async void initialize()
    {
        var getAuthStatus = new NokiaIsi.IsiSimGetAuthStatus();
        try
        {
            yield getAuthStatus.run();

            if ( getAuthStatus.status == FreeSmartphone.GSM.SIMAuthStatus.READY )
            {
                theModem.advanceToState( Modem.Status.ALIVE_SIM_UNLOCKED );
            }
            else if ( getAuthStatus.status == FreeSmartphone.GSM.SIMAuthStatus.PIN_REQUIRED ||
                      getAuthStatus.status == FreeSmartphone.GSM.SIMAuthStatus.PUK_REQUIRED )
            {
                theModem.advanceToState( Modem.Status.ALIVE_SIM_LOCKED );
            }

        }
        catch ( FreeSmartphone.GSM.Error e1 )
        {
            if ( e1 is FreeSmartphone.GSM.Error.SIM_NOT_PRESENT )
            {
                theModem.advanceToState( Modem.Status.ALIVE_NO_SIM );
            }
            else
            {
                theModem.logger.error( @"Unexpected FSO error: $(e1.message) - what now?" );
            }
        }
        catch ( Error e2 )
        {
            theModem.logger.error( @"Can't get SIM auth status: $(e2.message) - what now?" );
            // FIXME: move to close status?
        }

    }

    public async void shutdown()
    {
        if ( _is_initialized )
        {
            _is_initialized = false;
        }
    }

    public void registerUnsolicitedHandler( UnsolicitedHandler urchandler )
    {
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
}

