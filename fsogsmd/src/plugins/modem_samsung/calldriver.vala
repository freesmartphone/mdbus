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

public class Samsung.CallDriver : ICallDriver, FsoFramework.AbstractObject
{
    private Samsung.SoundHandler _soundhandler;
    private FsoGsm.Modem _modem;

    //
    // public API
    //

    public CallDriver( FsoGsm.Modem modem )
    {
        _modem = modem;
        _soundhandler = new Samsung.SoundHandler( _modem );
    }

    public async void dial( string number, string type ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = _modem.channel( "main" ) as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        // FIXME we want this right here?
        yield _soundhandler.mute_microphone( false );

        var initiateMessage = SamsungIpc.Call.OutgoingMessage();
        var callType = ( type == "voice" ) ? SamsungIpc.Call.Type.VOICE : SamsungIpc.Call.Type.DATA;
        var callPrefix = ( number.length >= 1 && number[0] == '+' ) ? SamsungIpc.Call.Prefix.INTL : SamsungIpc.Call.Prefix.NONE;
        initiateMessage.setup( callType, SamsungIpc.Call.Identity.DEFAULT, callPrefix, number );

        response = yield channel.enqueue_async( SamsungIpc.RequestType.EXEC,
            SamsungIpc.MessageType.CALL_OUTGOING, initiateMessage.data );

        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"The modem.failed to initiate a call with number $(number)" );

        var gr = (SamsungIpc.Generic.PhoneResponseMessage*) response.data;
        if ( gr.code != 0x8000 )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"modem.told us it can not initialize call with number $(number)" );

        // FIXME we want this right here?
        yield _soundhandler.mute_microphone( false );
        yield _soundhandler.set_speaker_volume( SamsungIpc.Sound.VolumeType.SPEAKER, 0x4 );
        yield _soundhandler.set_audio_path( SamsungIpc.Sound.AudioPath.HANDSET );
    }

    public async void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = _modem.channel( "main" ) as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        // FIXME we want this right here?
        yield _soundhandler.execute_clock_control();

        response = yield channel.enqueue_async( SamsungIpc.RequestType.EXEC, SamsungIpc.MessageType.CALL_ANSWER );

        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Didn't receive a response for our request from the modem." );

        var gr = (SamsungIpc.Generic.PhoneResponseMessage*) response.data;
        if ( gr.code != 0x8000 )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Something went wrong when trying to answer an incoming call" );

        // FIXME we want this right here?
        yield _soundhandler.mute_microphone( false );
    }

    public async void hold_all_active() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }

    public async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        var channel = _modem.channel( "main" ) as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        response = yield channel.enqueue_async( SamsungIpc.RequestType.EXEC, SamsungIpc.MessageType.CALL_RELEASE );
        if ( response == null )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Didn't receive a response for our request from the modem." );

        var gr = (SamsungIpc.Generic.PhoneResponseMessage*) response.data;
        if ( gr.code != 0x8000 )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Could not release call with id = $(id)" );
    }

    public async void release_all_held() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }

    public async void release_all_active() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }

    public async void create_conference() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }

    public async void transfer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }

    public async void deflect( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }

    public async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }

    public async void cancel_outgoing_with_id( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }

    public async void reject_incoming_with_id( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
        throw new FreeSmartphone.Error.UNSUPPORTED( "Not implemented" );
    }

    public override string repr()
    {
        return @"<>";
    }
}
