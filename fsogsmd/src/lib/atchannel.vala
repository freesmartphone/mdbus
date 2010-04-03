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

public class FsoGsm.AtChannel : FsoGsm.AtCommandQueue, FsoGsm.Channel
{
    protected string name;

    private bool isMainChannel;

    public AtChannel( string name, FsoFramework.Transport transport, FsoFramework.Parser parser )
    {
        base( transport, parser );
        this.name = name;
        theModem.registerChannel( name, this );

        theModem.signalStatusChanged += onModemStatusChanged;

        this.isMainChannel = ( name == "main" );
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
            default:
                break;
        }
    }

    private async void initialize()
    {
        if ( this.isMainChannel )
        {
            var seq1 = theModem.atCommandSequence( "MODEM", "init" );
            yield seq1.performOnChannel( this );
        }

        var seq2 = theModem.atCommandSequence( "CHANNEL", "init" );
        yield seq2.performOnChannel( this );

        var seq3 = theModem.atCommandSequence( name, "init" );
        yield seq3.performOnChannel( this );

        // select charset, try to lock to preferred one (if available)
        var charset = yield configureCharset( { theModem.data().charset, "UTF8", "UCS2", "HEX", "IRA" } );

        if ( charset == "unknown" )
        {
            theModem.logger.warning( "Modem does not support the charset command or any of UTF8, UCS2, HEX, IRA" );
        }
        else
        {
            theModem.logger.info( @"Channel successfully configured for charset '$charset'" );
        }
        theModem.data().charset = charset;

        if ( this.isMainChannel )
        {
            // charset ok, now it's save to call mediators
            gatherSimStatusAndUpdate();
        }
    }

    private async void simIsReady()
    {
        var seq = theModem.atCommandSequence( name, "unlocked" );
        yield seq.performOnChannel( this );
    }

    private async void simHasRegistered()
    {
        var seq = theModem.atCommandSequence( name, "registered" );
        yield seq.performOnChannel( this );
    }

    private async string configureCharset( string[] charsets )
    {
        theModem.logger.info( "Configuring modem charset..." );

        for ( int i = 0; i < charsets.length; ++i )
        {
            var cmd = theModem.createAtCommand<PlusCSCS>( "+CSCS" );
            var response = yield enqueueAsync( cmd, cmd.issue( charsets[i] ) );
            if ( cmd.validateOk( response ) == Constants.AtResponse.OK )
            {
                return charsets[i];
            }
        }
        return "unknown";
    }

    public void injectResponse( string response )
    {
        parser.feed( response, (int)response.length );
    }

    public async bool suspend()
    {
        var seq = theModem.atCommandSequence( name, "suspend" );
        yield seq.performOnChannel( this );
        return true;
    }

    public async bool resume()
    {
        var seq = theModem.atCommandSequence( name, "resume" );
        yield seq.performOnChannel( this );
        return true;
    }
}

