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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

using Alsa;

/**
 * Errordomain
 **/
public errordomain FsoAudio.SoundError
{
    NO_DEVICE,
    DEVICE_ERROR,
    NOT_ENOUGH_CONTROLS,
    INVALID_DESCRIPTOR,
}

/**
 * @class FsoAudio.BunchOfMixerControls
 **/
public class FsoAudio.BunchOfMixerControls
{
    public FsoAudio.MixerControl[] controls;

    /**
     * Index of control that should be used as main speaker volume control
     **/
    public uint idxSpeakerVolume;

    /**
     * Index of control that should be used as main microphone volume control
     **/
    public uint idxMicVolume;

    public BunchOfMixerControls( FsoAudio.MixerControl[] controls, uint idxSpeakerVolume = 0, uint idxMicVolume = 0 )
    {
        this.controls = controls;
        this.idxSpeakerVolume = idxSpeakerVolume;
        this.idxMicVolume = idxMicVolume;
    }

    public string to_string()
    {
        var str = "";
        for ( int i = 0; i < controls.length; ++i )
        {
            str += @"$(controls[i])\n";
        }
        return str;
    }
}

/**
 * @class FsoAudio.SoundDevice
 *
 * Encapsulates access to one Alsa Mixer Device
 **/
public class FsoAudio.SoundDevice : FsoFramework.AbstractObject
{
    private Card card;
    private ElemList list;
    public string name;
    public string fullname;
    public string mixername;
    public string cardname;

    private SoundDevice( ref Card card, ref ElemList list, string name, string fullname, string mixername, string cardname )
    {
        this.card = (owned) card;
        this.list = (owned) list;
        this.name = name;
        this.fullname = fullname;
        this.mixername = mixername;
        this.cardname = cardname;
    }

    /**
     * Create @a SoundDevice class, attached to a specific Alsa card.
     **/
    public static SoundDevice create( string cardname = "default" ) throws SoundError
    {
        Card card;

        int res = Card.open( out card, cardname );
        if ( res < 0 )
            throw new SoundError.NO_DEVICE( "%s".printf( Alsa.strerror( res ) ) );

        CardInfo info;
        res = CardInfo.alloc( out info );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        res = card.card_info( info );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        ElemList list;
        res = ElemList.alloc( out list );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        res = card.elem_list( list );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        list.set_offset( 0 );
        res = list.alloc_space( list.get_count() );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        res = card.elem_list( list );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        return new SoundDevice( ref card, ref list, info.get_id(), info.get_longname(), info.get_mixername(), cardname );
    }

    public override string repr()
    {
        return @"<$name>";
    }

    public MixerControl controlForId( uint idx ) throws SoundError
    {
        ElemId eid;
        var res = ElemId.alloc( out eid );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        assert( list != null );
        list.get_id( idx, eid );

        ElemInfo info;
        res = ElemInfo.alloc( out info );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        info.set_id( eid );

        res = card.elem_info( info );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        ElemValue value;
        res = ElemValue.alloc( out value );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        value.set_id( eid );

        res = card.elem_read( value );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        return new MixerControl( ref eid, ref info, ref value );
    }

    /**
     * Set control to the value specified by @a MixerControl.
     **/
    public void setControl( MixerControl control ) throws SoundError
    {
        var type = control.info.get_type();
        if ( type != ElemType.IEC958 )
        {
            var res = card.elem_write( control.value );
            if ( res < 0 )
                throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );
        }
        else
        {
#if DEBUG
            debug( "Ignoring IEC958 setting" );
#endif
        }
    }

    /**
     * Get all controls (aka a scenario).
     **/
    public MixerControl[] allMixerControls() throws SoundError
    {
        MixerControl[] controls = {};
        var count = list.get_count();

        for ( int i = 0; i < count; ++i )
        {
            controls += controlForId( i );
        }
        return controls;
    }

    /**
     * Set all controls (aka a scenario).
     **/
    public void setAllMixerControls( MixerControl[] controls ) throws SoundError
    {
        foreach ( var control in controls )
            setControl( control );
    }

    /**
     * Construct @a MixerControl from a string description.
     **/
    public MixerControl controlForString( string description ) throws SoundError
    {
        var strings = description.split( ":" );
        if ( strings.length != 4 )
            throw new SoundError.INVALID_DESCRIPTOR( "Expected 4 descriptor components, got %d".printf( strings.length ) );
        var idx = strings[0].to_int();
        //var name = strings[1].replace( "'", "" );
        var count = strings[2].to_int();
        var segments = strings[3].strip().split( "," );
        if ( segments.length != count )
            throw new SoundError.INVALID_DESCRIPTOR( "Expected %d value parameters, got %d".printf( count, segments.length ) );

        // populate defaults
        var control = controlForId( idx - 1 );
        // overwrite with values from string

        switch ( control.info.get_type() )
        {
            case ElemType.BOOLEAN:
                for ( var i = 0; i < count; ++i )
                    control.value.set_boolean( i, segments[i] == "1" );
                break;
            case ElemType.INTEGER:
                for ( var i = 0; i < count; ++i )
                    control.value.set_integer( i, segments[i].to_int() );
                break;
            case ElemType.INTEGER64:
                for ( var i = 0; i < count; ++i )
                    control.value.set_integer64( i, segments[i].to_int64() );
                break;
            case ElemType.ENUMERATED:
                for ( var i = 0; i < count; ++i )
                    control.value.set_enumerated( i, segments[i].to_int() );
                break;
            case ElemType.BYTES:
                for ( var i = 0; i < count; ++i )
                    control.value.set_byte( i, (uchar) ( segments[i].to_int() & 0xff ) );
                break;
            case ElemType.IEC958:
#if DEBUG
                debug( "Can't restore IEC958 element" );
#endif
                break;
            default:
                warning( "Unknown type %d... ignoring".printf( control.info.get_type() ) );
                break;
        }
        return control;
    }

    /**
     * @return volume percent for mixer element with @a id
     **/
    public uint8 volumeForIndex( uint id )
    {
        Alsa.Mixer mix;
        Alsa.Mixer.open( out mix );
        assert( mix != null );
        mix.attach( cardname );
        mix.register();
        mix.load();

        Alsa.MixerElement mel = mix.first_elem();
        if( mel == null )
        {
            warning( "mix.first_elem() returned NULL" );
            return 0;
        }
        while ( id-- > 0 )
        {
            mel = mel.next();
            assert( mel != null );
        }

        long val;
        long min;
        long max;
        mel.get_playback_volume( Alsa.SimpleChannelId.MONO, out val );
        mel.get_playback_volume_range( out min, out max );

        return (uint8) Math.round(( (val-min) * 100 / (double)( max-min ) ) );
    }

    /**
     * @set volume percent for mixer element with @a id
     **/
    public void setVolumeForIndex( uint id, uint8 val )
    {
        Alsa.Mixer mix;
        Alsa.Mixer.open( out mix );
        assert( mix != null );
        mix.attach( cardname );
        mix.register();
        mix.load();

        Alsa.MixerElement mel = mix.first_elem();
        if( mel == null )
        {
            warning( "mix.first_elem() returned NULL" );
            return;
        }
        while ( id-- > 0 )
        {
            mel = mel.next();
            assert( mel != null );
        }

        long min;
        long max;
        mel.get_playback_volume_range( out min, out max );
        mel.set_playback_volume_all( min + val * ( max-min ) / 100 );
    }
}

/**
 * @class FsoAudio.MixerControl
 *
 * Encapsulates access to one mixer control
 **/
public class FsoAudio.MixerControl
{
    public ElemId eid;
    public ElemInfo info;
    public ElemValue value;

    public MixerControl( ref ElemId eid, ref ElemInfo info, ref ElemValue value )
    {
        this.eid = (owned) eid;
        this.info = (owned) info;
        this.value = (owned) value;
    }

    public string to_string()
    {
        var infoline = "%u:'%s':%u:".printf( eid.get_numid(), eid.get_name(), info.get_count() );

        var type = info.get_type();
        var count = info.get_count();

        switch (type)
        {
            case ElemType.BOOLEAN:
                for ( var i = 0; i < count; ++i )
                    infoline += "%u,".printf( (uint)value.get_boolean( i ) );
                break;
            case ElemType.INTEGER:
                for ( var i = 0; i < count; ++i )
                    infoline += "%ld,".printf( value.get_integer( i ) );
                break;
            case ElemType.INTEGER64:
                for ( var i = 0; i < count; ++i )
                    infoline += "%ld,".printf( (long)value.get_integer64( i ) );
                break;
            case ElemType.ENUMERATED:
                for ( var i = 0; i < count; ++i )
                    infoline += "%u,".printf( value.get_enumerated( i ) );
                break;
            case ElemType.BYTES:
                for ( var i = 0; i < count; ++i )
                    infoline += "%2.2x,".printf( value.get_byte( i ) );
                break;
            case ElemType.IEC958:
                AesIec958 iec958 = {};
                value.get_iec958( iec958 );
                infoline += "<IEC958>";
                break;
            default:
                for ( var i = 0; i < count; ++i )
                    infoline += "<unknown>,";
                break;
        }
        return ( infoline[infoline.length-1] == ',' ) ? infoline.substring( 0, infoline.length-1 ) : infoline;
    }

    public uint volume {
        set {
            assert_not_reached();
        }

        get {
            assert_not_reached();
        }
    }
}

/**
 * @class FsoAudio.PcmDevice
 *
 * Encapsulates access to a PCM device
 **/
public class FsoAudio.PcmDevice
{
    private string name;
    public Alsa.PcmDevice device;
    private Alsa.PcmHardwareParams hwparams;
    private int rate;
    private Alsa.PcmAccess access;
    private Alsa.PcmFormat format;
    private uint channels;

    //
    // Private API
    //

    private void checkedCall( string purpose, int err ) throws SoundError
    {
        if ( err < 0 )
        {
            throw new SoundError.DEVICE_ERROR( @"Can't $purpose: $(Alsa.strerror(err))" );
        }
    }

    //
    // Public API
    //

    public void open( string devicename = "default", Alsa.PcmStream mode = Alsa.PcmStream.PLAYBACK ) throws SoundError
    {
        checkedCall( @"open PCM device '$devicename'", Alsa.PcmDevice.open( out device, devicename, mode, 0 ) );
        assert( device != null );
        this.name = devicename;
        Alsa.PcmHardwareParams.malloc( out hwparams );
    }

    public void setFormat( Alsa.PcmAccess access, Alsa.PcmFormat format, int desiredrate = 44100, uint channels = 2 ) throws SoundError
    {
        this.rate = desiredrate;
        this.access = access;
        this.format = format;
        this.channels = channels;

        checkedCall( "hw_params_any", device.hw_params_any( hwparams ) );
        checkedCall( "hw_params_set_access", device.hw_params_set_access( hwparams, access ) );
        checkedCall( "hw_params_set_format", device.hw_params_set_format( hwparams, format ) );
        checkedCall( "hw_params_set_rate_near", device.hw_params_set_rate_near( hwparams, ref rate, 0 ) );
        checkedCall( "hw_params_set_channels", device.hw_params_set_channels( hwparams, channels ) );
        checkedCall( "hw_params", device.hw_params( hwparams ) );
        checkedCall( "prepare", device.prepare() );
    }

    public void close()
    {
        var err = device.close();

        if ( err < 0 )
        {
            warning( @"Can't close opened PCM device '$name': $(Alsa.strerror(err))" );
        }
    }

    public void prepare() throws SoundError
    {
	checkedCall( "prepare", device.prepare() );
    }


    public Alsa.PcmSignedFrames writei( uint8[] buf, Alsa.PcmUnsignedFrames size ) throws SoundError
    {
        return device.writei( buf, size );
    }

    public Alsa.PcmSignedFrames writen( uint8*[] buf, Alsa.PcmUnsignedFrames size ) throws SoundError
    {
        return device.writen( buf, size );
    }

    public Alsa.PcmSignedFrames readi( uint8[] buf, Alsa.PcmUnsignedFrames size ) throws SoundError
    {
        return device.readi( buf, size );
    }

    public Alsa.PcmSignedFrames readn( uint8*[] buf, Alsa.PcmUnsignedFrames size ) throws SoundError
    {
        return device.readn( buf, size );
    }
    public int recover(int error,int silent)
    {
        return device.recover(error,silent);
    }

}

// vim:ts=4:sw=4:expandtab
