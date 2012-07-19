/*
 * Copyright (C) 2011-2012 Simon Busch <morphis@gravedo.de>
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

using Gee;
using FsoGsm;

internal const int CALL_STATUS_REFRESH_TIMEOUT = 3; // in seconds

/**
 * @class Samsung.CallHandler
 */

public class Samsung.CallHandler : FsoGsm.AbstractCallHandler
{
    private Samsung.SoundHandler _soundhandler;

    //
    // public API
    //

    public CallHandler( FsoGsm.Modem modem )
    {
        base( modem );
        _soundhandler = new Samsung.SoundHandler( modem );
    }

    public override async int initiate( string number, string ctype ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = modem.channel( "main" ) as Samsung.IpcChannel;
        var num = lowestOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.RELEASE );
        unowned SamsungIpc.Response? response = null;

        validatePhoneNumber( number );

        if ( num == 0 )
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "System busy" );

        yield _soundhandler.mute_microphone( false );

        var initiateMessage = SamsungIpc.Call.OutgoingMessage();
        var callType = ( ctype == "voice" ) ? SamsungIpc.Call.Type.VOICE : SamsungIpc.Call.Type.DATA;
        var callPrefix = ( number.length >= 1 && number[0] == '+' ) ? SamsungIpc.Call.Prefix.INTL : SamsungIpc.Call.Prefix.NONE;
        initiateMessage.setup( callType, SamsungIpc.Call.Identity.DEFAULT, callPrefix, number );

        response = yield channel.enqueue_async( SamsungIpc.RequestType.EXEC,
            SamsungIpc.MessageType.CALL_OUTGOING, initiateMessage.data );

        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"The modem failed to initiate a call with number $(number)" );

        var gr = (SamsungIpc.Generic.PhoneResponseMessage*) response.data;
        if ( gr.code != 0x8000 )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Modem told us it can not initialize call with number $(number)" );

        yield _soundhandler.mute_microphone( false );
        yield _soundhandler.set_speaker_volume( SamsungIpc.Sound.VolumeType.SPEAKER, 0x4 );
        yield _soundhandler.set_audio_path( SamsungIpc.Sound.AudioPath.HANDSET );

        startTimeoutIfNecessary();

        return num;
    }

    public override void addSupplementaryInformation( string direction, string info )
    {
        supplementary = new FsoFramework.Pair<string,string>( direction, info );
    }

    public override async void activate( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = modem.channel( "main" ) as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        if ( id < 1 || id > Constants.CALL_INDEX_MAX )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Call index needs to be within [ 1, %d ]".printf( (int)Constants.CALL_INDEX_MAX) );
        }
        if ( calls[id].detail.status != FreeSmartphone.GSM.CallStatus.INCOMING && calls[id].detail.status != FreeSmartphone.GSM.CallStatus.HELD )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No suitable call to activate found" );
        }

        if ( numberOfBusyCalls() == 0 )
        {
            yield _soundhandler.execute_clock_control();

            response = yield channel.enqueue_async( SamsungIpc.RequestType.EXEC, SamsungIpc.MessageType.CALL_ANSWER );

            if ( response == null )
                throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Didn't receive a response for our request from the modem!" );

            var gr = (SamsungIpc.Generic.PhoneResponseMessage*) response.data;
            if ( gr.code != 0x8000 )
                throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Something went wrong when trying to answer an incoming call" );

            yield _soundhandler.mute_microphone( false );
        }
    }

    public override async void hold() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.ACTIVE ) == 0 )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No active call present" );
        }
        if ( numberOfCallsWithStatus( FreeSmartphone.GSM.CallStatus.INCOMING ) > 0 )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "Call incoming. Can't hold active calls without activating" );
        }
    }

    public override async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = modem.channel( "main" ) as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        if ( id < 1 || id > Constants.CALL_INDEX_MAX )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Call index needs to be within [ 1, %d ]".printf( (int)Constants.CALL_INDEX_MAX) );
        }
        else if ( calls[id].detail.status == FreeSmartphone.GSM.CallStatus.RELEASE )
        {
            throw new FreeSmartphone.GSM.Error.CALL_NOT_FOUND( "No suitable call to release found" );
        }

        response = yield channel.enqueue_async( SamsungIpc.RequestType.EXEC, SamsungIpc.MessageType.CALL_RELEASE );
        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Didn't receive a response for our request from the modem!" );

        var gr = (SamsungIpc.Generic.PhoneResponseMessage*) response.data;
        if ( gr.code != 0x8000 )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Could not release call with id = $(id)" );
    }

    public override async void releaseAll() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
       for ( int i = Constants.CALL_INDEX_MIN; i != Constants.CALL_INDEX_MAX; ++i )
        {
            if ( calls[i].detail.status != FreeSmartphone.GSM.CallStatus.RELEASE &&
                 calls[i].detail.status != FreeSmartphone.GSM.CallStatus.INCOMING )
            {
                release( i );
            }
        }
    }

    public override async void transfer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public override async void deflect( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public override async void conference( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public override async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public override string repr()
    {
        return @"<>";
    }

    public async void syncCallStatusAsync()
    {
        startTimeoutIfNecessary();
    }

    //
    // protected
    //

    protected override async void syncCallStatus()
    {
        inSyncCallStatus = true;

        try
        {
            assert( logger.debug( "Synchronizing call status" ) );
            var m = modem.createMediator<FsoGsm.CallListCalls>();
            yield m.run();

            // workaround for https://bugzilla.gnome.org/show_bug.cgi?id=585847
            var length = 0;
            foreach ( var c in m.calls )
            {
                length++;
            }
            // </workaround>

            assert( logger.debug( @"$(length) calls known in the system" ) );

            // stop timer if there are no more calls
            if ( length == 0 )
            {
                assert( logger.debug( "call status idle -> stopping updater" ) );
                Source.remove( timeout );
                timeout = 0;
            }

            if ( supplementary != null )
            {
                // add supplementary information to incoming or outgoing
                foreach ( var ca in m.calls )
                {
                    var direction = ca.properties.lookup( "direction" ).get_string();
                    if ( direction == supplementary.first )
                    {
                        ca.properties.insert( "service", supplementary.second );
                    }
                }
                supplementary = null;
            }

            // visit all busy (incoming,outgoing,held,active) calls to send updates...
            var visited = new bool[Constants.CALL_INDEX_MAX+1];
            foreach ( var call in m.calls )
            {
                assert( logger.debug( @"Updating call with id = $(call.id) ..." ) );

                if ( call.id < 0 || call.id > Constants.CALL_INDEX_MAX )
                {
                    logger.warning( @"Got call with invalid id = $(call.id); discarding this one!" );
                    continue;
                }

                calls[call.id].update( call );
                visited[call.id] = true;
            }

            // ...and synthesize updates for (now) released calls
            for ( int i = Constants.CALL_INDEX_MIN; i != Constants.CALL_INDEX_MAX; ++i )
            {
                if ( ! visited[i] && calls[i].detail.status != FreeSmartphone.GSM.CallStatus.RELEASE )
                {
                    var detail = FreeSmartphone.GSM.CallDetail(
                        i,
                        FreeSmartphone.GSM.CallStatus.RELEASE,
                        new GLib.HashTable<string,GLib.Variant>( str_hash, str_equal )
                    );

                    /*
                    var ceer = modem.createAtCommand<PlusCEER>( "+CEER" );
                    var result = yield modem.processAtCommandAsync( ceer, ceer.execute() );
                    if ( ceer.validate( result ) == Constants.AtResponse.VALID )
                    {
                        detail.properties.insert( "cause", ceer.reason );
                    }
                    */

                    calls[i].update( detail );
                }
            }
        }
        catch ( GLib.Error e )
        {
            logger.error( @"Can't synchronize call status: $(e.message)" );
        }

        inSyncCallStatus = false;
    }

    protected override async void cancelOutgoingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        assert( logger.debug( @"Cancelling outgoing call with ID $id" ) );
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented!" );
    }

    protected override async void rejectIncomingWithId( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        assert( logger.debug( @"Rejecting incoming call with ID $id" ) );
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not yet implemented!" );
    }
}

// vim:ts=4:sw=4:expandtab
