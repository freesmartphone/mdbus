/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public class FsoGsm.AtChannel : FsoGsm.AtCommandQueue, FsoGsm.Channel
{
    private static bool isMainInitialized;

    protected string name;
    private bool isInitialized;
    private bool isMainChannel;
    private bool isUrcChannel;
    private FsoGsm.Modem modem;

    public AtChannel( FsoGsm.Modem modem, string? name, FsoFramework.Transport transport, FsoFramework.Parser parser, bool isUrcChannel = true )
    {
        base( transport, parser );
        this.name = name;
        this.modem = modem;

        if ( name != null ) // anonymous channels will not get registered with the modem
        {
            modem.registerChannel( name, this );
            modem.signalStatusChanged.connect( onModemStatusChanged );
            this.isMainChannel = ( name == "main" );
            this.isUrcChannel = isUrcChannel;
        }
    }

    public void onModemStatusChanged( FsoGsm.Modem modem, FsoGsm.Modem.Status status )
    {
        switch ( status )
        {
            case Modem.Status.INITIALIZING:
                initialize();
                break;
            case Modem.Status.ALIVE_SIM_READY:
                simIsReady();
                break;
            case Modem.Status.ALIVE_REGISTERED:
                simHasRegistered();
                break;
            case Modem.Status.CLOSING:
                shutdown();
                break;
            default:
                break;
        }
    }

    private async void initialize()
    {
        assert( modem.logger.debug( @"Initializing channel $name ..." ) );

        if ( this.isMainChannel )
        {
            var seq1 = modem.atCommandSequence( "MODEM", "init" );
            yield seq1.performOnChannel( this );
            isMainInitialized = true;
        }

        while ( !isMainInitialized )
        {
            // make sure that we still are initializing; if not, just return as
            // we obviously have been requested to shutdown then
            if ( modem.status() == Modem.Status.CLOSING )
            {
                return;
            }
            // check wether the main channel successfully initialized the modem
            else if ( modem.status() == Modem.Status.ALIVE_SIM_READY )
            {
                isMainInitialized = true;
                break;
            }

            modem.logger.debug( "Main channel not initialized yet... waiting" );
            Timeout.add_seconds( 1, initialize.callback );
            yield;
        }

        var seq2 = modem.atCommandSequence( "CHANNEL", "init" );
        yield seq2.performOnChannel( this );

        var seq3 = modem.atCommandSequence( name, "init" );
        yield seq3.performOnChannel( this );

        // select charset, try to lock to preferred one (if available)
        var charset = yield configureCharset( { modem.data().charset, "UTF8", "UCS2", "HEX", "IRA" } );

        if ( charset == "unknown" )
        {
            modem.logger.warning( "Modem does not support the charset command or any of UTF8, UCS2, HEX, IRA" );
        }
        else
        {
            assert( modem.logger.debug( @"Channel successfully configured for charset '$charset'" ) );
        }
        modem.data().charset = charset;

        if ( this.isUrcChannel )
        {
            setupNetworkRegistrationReport();
        }

        if ( this.isMainChannel )
        {
            gatherSimStatusAndUpdate( modem );
            modem.smshandler.configure();
        }

        this.isInitialized = true;
    }

    private async void shutdown()
    {
        assert( modem.logger.debug( @"Shutting down channel $name ..." ) );

        if ( this.isMainChannel )
        {
            if ( this.isInitialized )
            {
                var seq = modem.atCommandSequence( "MODEM", "shutdown" );
                yield seq.performOnChannel( this );
            }
            else
            {
                modem.logger.info( "Not sending shutdown commands, since modem hasn't been initialized yet" );
            }
        }
    }

    private async void simIsReady()
    {
        var seq = modem.atCommandSequence( name, "unlocked" );
        yield seq.performOnChannel( this );
    }

    private async void simHasRegistered()
    {
        var seq = modem.atCommandSequence( name, "registered" );
        yield seq.performOnChannel( this );
    }

    private async string configureCharset( string[] charsets )
    {
        assert( modem.logger.debug( "Configuring modem charset..." ) );

        for ( int i = 0; i < charsets.length; ++i )
        {
            var cmd = modem.createAtCommand<PlusCSCS>( "+CSCS" );
            var response = yield enqueueAsync( cmd, cmd.issue( charsets[i] ) );
            if ( cmd.validateOk( response ) == Constants.AtResponse.OK )
            {
                return charsets[i];
            }
        }
        return "unknown";
    }

    private async void setupNetworkRegistrationReport()
    {
        string[] response = { };
        var cmd = modem.createAtCommand<PlusCREG>( "+CREG" );

        response = yield enqueueAsync( cmd, cmd.issue( PlusCREG.Mode.ENABLE_WITH_NETORK_REGISTRATION_AND_LOCATION ) );
        if ( cmd.validateOk( response ) == Constants.AtResponse.OK )
            return;

        response = yield enqueueAsync( cmd, cmd.issue( PlusCREG.Mode.ENABLE_WITH_NETORK_REGISTRATION ) );
        if ( cmd.validateOk( response ) != Constants.AtResponse.OK )
        {
            modem.logger.error( "Failed to setup network registration reporting; reports will not be avaible ..." );
        }
    }

    public void injectResponse( string response )
    {
        parser.feed( response, (int)response.length );
    }

    public async bool suspend()
    {
        var seq = modem.atCommandSequence( name, "suspend" );
        yield seq.performOnChannel( this );
        return true;
    }

    public async bool resume()
    {
        var seq = modem.atCommandSequence( name, "resume" );
        yield seq.performOnChannel( this );
        return true;
    }
}

// vim:ts=4:sw=4:expandtab
