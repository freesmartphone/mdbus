/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

public class FsoGsm.Channel : FsoFramework.BaseCommandQueue
{
    private static int numChannelsInitialized;

    protected string name;
    protected string[] initSequence;
    protected string[] unlockedSequence;
    protected string[] registeredSequence;
    protected string[] suspendSequence;
    protected string[] resumeSequence;

    private bool isMainChannel;

    static construct
    {
        numChannelsInitialized = 0;
    }

    public Channel( string name, FsoFramework.Transport transport, FsoFramework.Parser parser )
    {
        base( transport, parser );
        this.name = name;
        theModem.registerChannel( name, this );

        theModem.signalStatusChanged += onModemStatusChanged;

        initSequence = theModem.config.stringListValue( "fsogsm", @"channel_init_$name", { } );
        unlockedSequence = theModem.config.stringListValue( "fsogsm", @"channel_unlocked_$name", { } );
        registeredSequence = theModem.config.stringListValue( "fsogsm", @"channel_registered_$name", { } );
        suspendSequence = theModem.config.stringListValue( "fsogsm", @"channel_suspend_$name", { } );
        resumeSequence = theModem.config.stringListValue( "fsogsm", @"channel_resume_$name", { } );

        if ( numChannelsInitialized++ < 1 )
        {
            this.isMainChannel = true;
        }
        else
        {
            this.isMainChannel = false;
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
            default:
                break;
        }
    }

    private async void initialize()
    {
        if ( this.isMainChannel )
        {
            var sequence = theModem.commandSequence( "init" );
            yield sendCommandSequence( sequence );
        }
        yield sendCommandSequence( initSequence );

        var charset = yield configureCharset( { "UTF8", "UCS2", "IRA" } );

        if ( charset == "unknown" )
        {
            theModem.logger.warning( "Modem does not support the charset command or any of UTF8, UCS2, IRA" );
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
        yield sendCommandSequence( unlockedSequence );
    }

    private async string configureCharset( string[] charsets )
    {
        theModem.logger.info( "Configuring modem charset..." );

        for ( int i = 0; i < charsets.length; ++i )
        {
            var cmd = theModem.createAtCommand<PlusCSCS>( "+CSCS" );
            var response = yield enqueueAsyncYielding( cmd, cmd.issue( charsets[i] ) );
            if ( cmd.validateOk( response ) == Constants.AtResponse.OK )
            {
                return charsets[i];
            }
        }
        return "unknown";
    }

    private async void sendCommandSequence( string[] sequence )
    {
        foreach( var element in sequence )
        {
            var cmd = theModem.createAtCommand<CustomAtCommand>( "CUSTOM" );
            var response = yield enqueueAsyncYielding( cmd, element );
        }
    }

    public void injectResponse( string response )
    {
        onReadFromTransport( response );
    }
}

