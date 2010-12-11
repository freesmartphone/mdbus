/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public class IsiChannel : IsiCommandQueue, FsoGsm.Channel
{
    public FsoFramework.Transport transport { get; set; }
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
            case FsoGsm.Modem.Status.CLOSING:
                shutdown();
                break;
            default:
                break;
        }
    }


    //
    // public API
    //

    public IsiChannel( string name )
    {
        base( new FsoFramework.NullTransport() );
        this.name = name;
        theModem.registerChannel( name, this );
        theModem.signalStatusChanged.connect( onModemStatusChanged );

    }

    public void initialize()
    {
        theModem.logger.debug("ISICHANNEL: initialize ...");

        _is_initialized = true;

        theModem.logger.debug("ISICHANNEL: modem initialization is finished!");
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

