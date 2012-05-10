/*
 * Copyright (C) 2012 Simon Busch <morphis@gravedo.de>
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
using FsoFramework;

public class Samsung.RfsChannel : FsoGsm.Channel, FsoFramework.AbstractCommandQueue
{
    private SamsungIpc.Client rfsclient;
    private FsoFramework.Wakelock wakelock;

    public string name { get; private set; }

    public delegate void UnsolicitedHandler( string prefix, string response, string? pdu = null );

    //
    // private
    //

    public override void onTransportDataAvailable( FsoFramework.Transport t )
    {
        SamsungIpc.Response request = SamsungIpc.Response();

        wakelock.acquire();

        assert( theLogger.debug( @"Received data from modem; start processing ..." ) );

        var rc = rfsclient.recv(out request);
        if ( rc != 0 )
        {
            theLogger.error( @"Something went wrong while receiving data from the modem ... discarding this request!" );
            return;
        }

        assert( theLogger.debug( @"Got RFS request from modem: command = $(request.command)" ) );

        if ( request.command == SamsungIpc.MessageType.RFS_NV_WRITE_ITEM )
            SamsungIpc.Rfs.send_io_confirm_for_nv_write_item( rfsclient, request );
        else if ( request.command == SamsungIpc.MessageType.RFS_NV_READ_ITEM )
            SamsungIpc.Rfs.send_io_confirm_for_nv_read_item( rfsclient, request );

        // libsamsung-ipc allocates some memory for the response data which is not being
        // freed otherwise
        free(request.data);

        assert( theLogger.debug( @"Handled request from modem successfully!" ) );

        wakelock.release();
    }

    protected int modem_read_request(uint8[] data)
    {
        if ( data == null  )
            return 0;

        return transport.read(data, data.length);
    }

    protected int modem_write_request(uint8[] data)
    {
        if ( data == null )
            return 0;

        return transport.write(data, data.length);
    }

    //
    // public API
    //

    public RfsChannel( string name, FsoFramework.Transport? transport )
    {
        base( transport );

        this.name = name;
        this.wakelock = new FsoFramework.Wakelock( "fsogsmd-modem-samsung-rfs" );

        theModem.registerChannel( name, this );

        rfsclient = new SamsungIpc.Client( SamsungIpc.ClientType.RFS );
        rfsclient.set_log_handler( ( message ) => { theLogger.info( message ); } );
        rfsclient.set_io_handlers( modem_read_request, modem_write_request );
    }

    public override async bool open()
    {
        bool result = true;

        result = yield transport.openAsync();
        if (!result)
            return false;

        rfsclient.open();

        return true;
    }

    public override async void close()
    {
        rfsclient.close();
        transport.close();
    }

    public async bool suspend()
    {
        return true;
    }

    public async bool resume()
    {
        return true;
    }

    public void registerUnsolicitedHandler( UnsolicitedHandler urchandler ) { }

    public void injectResponse( string response ) { assert_not_reached(); }
}

// vim:ts=4:sw=4:expandtab
