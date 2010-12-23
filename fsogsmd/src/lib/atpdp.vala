/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 **/

/**
 * @class AtPdpHandler
 *
 * This PdpHandler uses AT commands and ppp to implement the Pdp handler interface
 **/
public class FsoGsm.AtPdpHandler : FsoGsm.PdpHandler
{
    public const string PPP_LOG_FILE = "/var/log/ppp.log";
    protected const int WAIT_FOR_PPP_COMING_UP = 2;

    protected FsoFramework.GProcessGuard ppp;

    public override string repr()
    {
        return "<>";
    }

    private void onPppStopped()
    {
        logger.debug( "ppp has been stopped" );
        shutdownTransport();
        ppp = null;
        // inform base class
        disconnected();
    }

    //
    // protected API for subclasses
    //
    protected virtual string[] buildCommandLine()
    {
        var data = theModem.data();
        var cmdline = new string[] { data.pppCommand, theModem.allocateDataPort() };
        foreach ( var option in data.pppOptions )
        {
            cmdline += option;
        }
        return cmdline;
    }

    protected virtual bool launchPppDaemon( string[] cmdline )
    {
        ppp = new FsoFramework.GProcessGuard();
        return ppp.launch( cmdline );
    }

    protected async virtual void setupTransport()
    {
    }

    protected async virtual void enterDataState() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        // enter data state
        var cmd = theModem.createAtCommand<V250D>( "D" );
        var response = yield theModem.processAtCommandAsync( cmd, cmd.issue( "*99***1#", false ) );
        checkResponseConnect( cmd, response );
    }

    protected async virtual void leaveDataState()
    {
        // leave data state (ignoring response for now)
        var cmd = theModem.createAtCommand<PlusCGACT>( "+CGACT" );
        /* var response = */ yield theModem.processAtCommandAsync( cmd, cmd.issue( 0 ) );
        /* checkResponseOk( cmd, response ); */
    }

    protected virtual void shutdownTransport()
    {
    }

    //
    // public API
    //

    public async override void sc_activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( ppp != null && ppp.isRunning() )
        {
            return;
        }

        var cmdline = buildCommandLine();

        // where to log to
        cmdline += "logfile";
        cmdline += config.stringValue( "fsogsm", "ppp_log_destination", PPP_LOG_FILE );

        var data = theModem.data();

        if ( data.contextParams == null )
        {
            throw new FreeSmartphone.Error.INTERNAL_ERROR( "context parameters not set" );
        }

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

        // add our plugin
        cmdline += "plugin";
        cmdline += "%s/ppp2fsogsmd.so".printf( Config.PACKAGE_LIBDIR );

        assert( logger.debug( @"Launching ppp helper with commandline $(FsoFramework.StringHandling.stringListToString(cmdline))" ) );

        if ( !launchPppDaemon( cmdline ) )
        {
            ppp = null;
            logger.warning( "Could not launch PPP helper" );
            throw new FreeSmartphone.Error.SYSTEM_ERROR( "Could not launch PPP helper" );
        }
        else
        {
            ppp.stopped.connect( onPppStopped );
        }

        // wait shortly to check to catch the case when ppp exists immediately
        // due to invalid options or permissions or what not
        yield FsoFramework.asyncWaitSeconds( WAIT_FOR_PPP_COMING_UP );

        if ( ppp == null )
        {
            logger.warning( "PPP quit immediately; check options and permissions." );
            throw new FreeSmartphone.Error.SYSTEM_ERROR( "PPP helper quit immediately" );
        }

        yield enterDataState();
        yield setupTransport();
    }

    public async override void sc_deactivate()
    {
        yield leaveDataState();
        /*
        if ( ppp == null )
        {
            return;
        }
        if ( !ppp.isRunning() )
        {
            return;
        }
        ppp.stop(); // trigger stopping
        */
    }

    public string uintToIp4Address( uint32 address )
    {
        return "%u.%u.%u.%u".printf( address & 0xff,
                                     ( address >> 8 ) & 0xff,
                                     ( address >> 16 ) & 0xff,
                                     ( address >> 24 ) & 0xff );
    }

    public async override void statusUpdate( string status, GLib.HashTable<string,Variant> properties )
    {
        assert( logger.debug( @"Status update from PPP helper: $status" ) );
        Variant? viface = properties.lookup( "iface" );
        Variant? vlocal = properties.lookup( "local" );
        Variant? vgateway = properties.lookup( "gateway" );
        Variant? vdns1 = properties.lookup( "dns1" );
        Variant? vdns2 = properties.lookup( "dns2" );

        string local = "unknown";
        string gateway = "unknown";
        //FIXME: use customizable DNS default entries
        string dns1 = "8.8.8.8";
        string dns2 = "8.8.8.8";

        if ( viface != null )
        {
            assert( logger.debug( @"IPCP: Interface name is $(viface.get_string())" ) );
        }
        if ( vlocal != null )
        {
            local = uintToIp4Address(vlocal.get_uint32());
            assert( logger.debug( @"IPCP: Interface addr is $local" ) );
        }
        if ( vgateway != null )
        {
            gateway = uintToIp4Address(vgateway.get_uint32());
            assert( logger.debug( @"IPCP: Gateway   addr is $gateway" ) );
        }
        if ( vdns1 != null )
        {
            dns1 = uintToIp4Address(vdns1.get_uint32());
            assert( logger.debug( @"IPCP: DNS1      addr is $dns1" ) );
        }
        if ( vdns2 != null )
        {
            dns2 = uintToIp4Address(vdns2.get_uint32());
            assert( logger.debug( @"IPCP: DNS2      addr is $dns2" ) );
        }

        if ( viface != null && vlocal != null && vgateway != null )
        {
            this.connectedWithNewDefaultRoute( viface.get_string(), local, "255.255.255.0", gateway, dns1, dns2 );
        }
        else
        {
            assert( logger.debug( @"IPCP: Not enough information for default route" ) );
        }
    }
}
