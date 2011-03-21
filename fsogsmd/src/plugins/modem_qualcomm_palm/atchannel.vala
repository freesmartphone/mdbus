/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public class MsmAtChannel : FsoGsm.AtCommandQueue, FsoGsm.Channel
{
    private static bool isMainInitialized;

    protected string name;
    private bool isInitialized;

    public MsmAtChannel( string name, FsoFramework.Transport transport, FsoFramework.Parser parser )
    {
        base( transport, parser );
        this.name = name;

        theModem.registerChannel( name, this );
        theModem.signalStatusChanged.connect( onModemStatusChanged );
    }

    public void onModemStatusChanged( FsoGsm.Modem modem, FsoGsm.Modem.Status status )
    {
        switch ( status )
        {
            case Modem.Status.ALIVE_REGISTERED:
                initialize();
                break;
            default:
                break;
        }
    }

    private async void initialize()
    {
        var seq = theModem.atCommandSequence( name, "init" );
        yield seq.performOnChannel( this );

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

        this.isInitialized = true;
    }

    private async void shutdown()
    {
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

