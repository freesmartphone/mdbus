/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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

public class Samsung.SoundHandler : FsoFramework.AbstractObject
{
    public async void mute_microphone( bool mute ) throws FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        response = yield channel.enqueue_async( SamsungIpc.RequestType.SET, SamsungIpc.MessageType.SND_MIC_MUTE_CTRL, new uint8[] { mute ? 0x1 : 0x0 } );

        var gr = (SamsungIpc.Generic.PhoneResponseMessage*) response.data;
        if ( gr.code != 0x8000 )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"We can't %s the microphone together with the modem!".printf( mute ? "mute" : "unmute" ) );
    }

    public async void set_speaker_volume( SamsungIpc.Sound.VolumeType type, uint8 volume ) throws FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        var cmd = SamsungIpc.Sound.SpeakerVolumeControlMessage();
        cmd.type = type;
        cmd.volume = volume;

        response = yield channel.enqueue_async( SamsungIpc.RequestType.SET,
            SamsungIpc.MessageType.SND_SPKR_VOLUME_CTRL, cmd.data );

        var gr = (SamsungIpc.Generic.PhoneResponseMessage*) response.data;
        if ( gr.code != 0x8000 )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Can't set speaker volume together with the modem!" );
    }

    public async void set_audio_path( SamsungIpc.Sound.AudioPath path ) throws FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        response = yield channel.enqueue_async( SamsungIpc.RequestType.SET,
            SamsungIpc.MessageType.SND_AUDIO_PATH_CTRL, new uint8[] { path } );

        var gr = (SamsungIpc.Generic.PhoneResponseMessage*) response.data;
        if ( gr.code != 0x8000 )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Can't set correct audio path together with the modem!" );
    }

    public async void execute_clock_control() throws FreeSmartphone.Error
    {
        var channel = theModem.channel( "main" ) as Samsung.IpcChannel;
        unowned SamsungIpc.Response? response = null;

        response = yield channel.enqueue_async( SamsungIpc.RequestType.EXEC, SamsungIpc.MessageType.SND_CLOCK_CTRL, new uint8[] { 0x1 } );

        var gr = (SamsungIpc.Generic.PhoneResponseMessage*) response.data;
        if ( gr.code != 0x8000 )
            throw new FreeSmartphone.Error.INTERNAL_ERROR( @"Can't excute sound control on baseband side!" );
    }

    public override string repr()
    {
        return @"<>";
    }
}
