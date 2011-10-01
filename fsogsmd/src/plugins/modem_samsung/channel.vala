/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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

public class Samsung.IpcChannel : FsoGsm.Channel, FsoFramework.AbstractCommandQueue
{
    public string name;

    public delegate void UnsolicitedHandler( string prefix, string response, string? pdu = null );

    private bool is_initialized;
    private IOChannel iochannel;
    private int readwatch;

    private void onModemStatusChanged( FsoGsm.Modem modem, FsoGsm.Modem.Status status )
    {
        switch ( status )
        {
            case FsoGsm.Modem.Status.INITIALIZING:
                break;
            case FsoGsm.Modem.Status.ALIVE_SIM_READY:
                break;
            case FsoGsm.Modem.Status.CLOSING:
                break;
            default:
                break;
        }
    }

    protected override void onReadFromTransport( FsoFramework.Transport t )
    {
    }

    //
    // public API
    //

    public IpcChannel( string name, FsoFramework.BaseTransport transport )
    {
        base( transport );
        this.name = name;
        theModem.registerChannel( name, this );
        theModem.signalStatusChanged.connect( onModemStatusChanged );
    }

    public override async bool open()
    {
        return true;
    }

    public override async void close()
    {
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

// vim:ts=4:sw=4:expandtab
