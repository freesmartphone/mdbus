/**
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
 **/

/**
 * @class MuxPppPdpHandler
 *
 * This PppHandler uses ppp over a multiplexed line to implement the Pdp handler interface
 **/
public class FsoGsm.MuxPppPdpHandler : FsoGsm.PdpHandler
{
    public const string PPP_LOG_FILE = "/var/log/ppp.log";

    private const int WAIT_FOR_PPP_COMING_UP = 2;

    private FsoFramework.GProcessGuard ppp;
    private LibGsm0710muxTransport transport;

    public override string repr()
    {
        return "<>";
    }

    private void onPppStopped()
    {
        //FIXME: check for expected or unexpected stop
        logger.debug( "ppp has been stopped" );
        var transport = theModem.channel( "data" ).transport as LibGsm0710muxTransport;

        if ( transport.isForwardingToPPP() )
        {
            // FIXME: check whether transport is still in data mode...,
            // and if so, try to return gracefully to command mode
            transport.stopForwardingToPPP();
        }

        ppp = null;
    }

    //
    // public API
    //
    public async override void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( ppp != null && ppp.isRunning() )
        {
            return;
        }

        // build ppp command line
        var data = theModem.data();
        var cmdline = new string[] { data.pppCommand };
        cmdline += "notty";
        cmdline += "logfile";
        cmdline += config.stringValue( "fsogsm", "ppp_log_destination", PPP_LOG_FILE );

        assert( data.contextParams != null );

        if ( data.contextParams.username != "" )
        {
            cmdline += "user";
            cmdline += data.contextParams.username;
        }
        if ( data.contextParams.password != "" )
        {
            cmdline += "password";
            cmdline += data.contextParams.password;
        }

        // add modem specific options to command line
        foreach ( var option in data.pppOptions )
        {
            cmdline += option;
        }

        // add our plugin
        cmdline += "plugin";
        cmdline += "%s/ppp2fsogsmd.so".printf( Config.PACKAGE_LIBDIR );

        // launch ppp
        ppp = new FsoFramework.GProcessGuard();

        var inputfd = 0;
        var outputfd = 0;

        ppp.stopped.connect( onPppStopped );
        if ( !ppp.launchWithPipes( cmdline, out inputfd, out outputfd ) )
        {
            throw new FreeSmartphone.Error.SYSTEM_ERROR( "Could not launch PPP helper" );
        }

        // wait shortly to check to catch the case when ppp exists immediately
        // due to invalid options or permissions or what not
        yield FsoFramework.asyncWaitSeconds( WAIT_FOR_PPP_COMING_UP );

        if ( ppp == null )
        {
            logger.warning( "PPP quit immediately; check options and permissions." );
            throw new FreeSmartphone.Error.SYSTEM_ERROR( "PPP helper quit immediately" );
        }

        // enter data state
        var cmd = theModem.createAtCommand<V250D>( "D" );
        var response = yield theModem.processCommandAsync( cmd, cmd.issue( "*99***1#" ) );
        checkResponseConnect( cmd, response );

        // start forwarding to ppp
        var transport = theModem.channel( "data" ).transport as LibGsm0710muxTransport;
        transport.startForwardingToPPP( inputfd, outputfd );
    }

    public async override void deactivate()
    {
        if ( ppp == null )
        {
            return;
        }
        if ( !ppp.isRunning() )
        {
            return;
        }
        ppp = null; // this will stop the process
    }

    public string uintToIpAddress( uint32 address )
    {
        return "%u.%u.%u.%u".printf( address & 0xff,
                                     ( address >> 8 ) & 0xff,
                                     ( address >> 16 ) & 0xff,
                                     ( address >> 24 ) & 0xff );
    }

    public async override void statusUpdate( string status, GLib.HashTable<string,Value?> properties )
    {
        assert( logger.debug( @"Status update from PPP helper: $status" ) );
        Value? viface = properties.lookup( "iface" );
        Value? vlocal = properties.lookup( "local" );
        Value? vgateway = properties.lookup( "gateway" );

        if ( viface != null )
        {
            assert( logger.debug( @"IPCP: Interface name is $(viface.get_string())" ) );
        }
        if ( vlocal != null )
        {
            assert( logger.debug( @"IPCP: Interface addr is $(uintToIpAddress(vlocal.get_uint()))" ) );
        }
        if ( vgateway != null )
        {
            assert( logger.debug( @"IPCP: Gateway   addr is $(uintToIpAddress(vgateway.get_uint()))" ) );
        }

        //FIXME: communicate with fsonetworkd to offer new route to internet
    }
}
