/*
 * Copyright (C) 2012 Simon Busch <morphis@gravedo.de>
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

public class FsoFramework.CombinedTransport : FsoFramework.BaseTransport
{
    private FsoFramework.Transport _rwtransport;
    private FsoFramework.Transport _rotransport;
    private int readswitch = 0; // 0: rwtransport, 1: rotransport

    //
    // private
    //

    private void onRwTransportRead( Transport transport )
    {
        if ( readfunc != null )
        {
            readswitch = 0;
            readfunc( transport );
        }
    }

    private void onRwTransportHup( Transport transport )
    {
        if ( hupfunc != null )
            hupfunc( transport );
    }

    private void onRoTransportRead( Transport transport )
    {
        if ( readfunc != null )
        {
            readswitch = 1;
            readfunc( transport );
        }
    }

    private void onRoTransportHup( Transport transport )
    {
        if ( hupfunc != null )
            hupfunc( transport );
    }

    //
    // public
    //

    public CombinedTransport( string transports )
    {
        base( "CombinedTransport" );

        //cut [ and ], put rwtransport string into _transports[0], put rotransport string into _transports[1]
        var _transports = transports.substring(1,(transports.length)-2).split( "," );
        string rw_transport = "";
        string rw_port = "";
        int rw_speed = -1;
        bool rw_ready = false;

        string ro_transport = "";
        string ro_port = "";
        int ro_speed = -1;
        bool ro_ready = false;

        var rw = _transports[0].split( ";" );
        if ( rw.length == 3 )
        {
            rw_transport = rw[0];
            rw_port = rw[1];
            rw_speed = int.parse( rw[2] );
            rw_ready = true;
        }
        else
        {
            logger.warning( @"Configuration string 'modem_access' (rwtransport) invalid; expected 3 parameters, got $(rw.length)" );
        }

        var ro = _transports[1].split( ";" );
        if ( ro.length == 3 )
        {
            ro_transport = ro[0];
            ro_port = ro[1];
            ro_speed = int.parse( ro[2] );
            ro_ready = true;
        }
        else
        {
            logger.warning( @"Configuration string 'modem_access' (rotransport) invalid; expected 3 parameters, got $(ro.length)" );
        }

        if ( rw_ready && ro_ready )
        {
            _rwtransport = FsoFramework.Transport.create( rw_transport, rw_port, rw_speed );
            _rwtransport.setDelegates( onRwTransportRead, onRwTransportHup );

            _rotransport = FsoFramework.Transport.create( ro_transport, ro_port, ro_speed );
            _rotransport.setDelegates( onRoTransportRead, onRoTransportHup );
        }
        else
        {
            logger.warning( @"Failed to create a combined transport (rw_ready/ro_ready): ($rw_ready/$ro_ready)" );
        }
    }

    public override bool open()
    {
        if ( !_rwtransport.open() )
            return false;

        if ( !_rotransport.open() )
        {
            _rwtransport.close();
            return false;
        }

        return true;
    }

    public override bool isOpen()
    {
        return _rwtransport.isOpen() && _rotransport.isOpen();
    }

    public override int write( void* data, int length )
    {
        return _rwtransport.write( data, length );
    }

    public override int read( void* data, int length )
    {
        if ( readswitch == 0 )
            return _rwtransport.read( data, length );
        else if ( readswitch == 1 )
            return _rotransport.read( data, length );
        return 0;
    }

    public override int freeze()
    {
        _rotransport.freeze();
        return _rwtransport.freeze();
    }

    public override void thaw()
    {
        _rwtransport.thaw();
        _rotransport.thaw();
    }

    public override void close()
    {
        _rwtransport.close();
        _rotransport.close();
    }

    public override void setBuffered( bool on )
    {
        _rwtransport.setBuffered( on );
    }

    public override int writeAndRead( void* wdata, int wlength, void* rdata, int rlength, int maxWait = 1000 )
    {
        return _rwtransport.writeAndRead( wdata, wlength, rdata, rlength, maxWait );
    }
}

