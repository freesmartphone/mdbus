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

using Alsa;

public errordomain FsoFramework.SoundError
{
    NO_DEVICE,
    DEVICE_ERROR,
    NOT_ENOUGH_CONTROLS,
}

/**
 * @class FsoFramework.SoundDevice
 **/
public class FsoFramework.SoundDevice : FsoFramework.AbstractObject
{
    private Card card;
    public string name;
    public string fullname;
    public string mixername;

    private SoundDevice( ref Card card, string name, string fullname, string mixername )
    {
        this.card = (owned) card;
        this.name = name;
        this.fullname = fullname;
        this.mixername = mixername;
    }

    public static SoundDevice create( string cardname = "default" ) throws FsoFramework.SoundError
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

        return new SoundDevice( ref card, info.get_id(), info.get_longname(), info.get_mixername() );
    }

    public override string repr()
    {
        return "<Device %s>".printf( name );
    }

    private MixerControl controlForId( ElemList list, uint idx ) throws SoundError
    {
        ElemId eid;
        var res = ElemId.alloc( out eid );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

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

    private void setControlForId( ElemList list, uint idx, MixerControl control ) throws SoundError
    {
        var type = control.info.get_type();
        if ( type != ElemType.IEC958 )
        {
            var res = card.elem_write( control.value );
            message( "idx=%u, res=%d", idx, res );
            if ( res < 0 )
                throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );
        }
        else
            message( "ignoring IEC958 setting" );
    }

    public MixerControl[] allMixerControls() throws SoundError
    {
        MixerControl[] controls = {};

        ElemList list;
        int res = ElemList.alloc( out list );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        res = card.elem_list( list );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        var count = list.get_count();

        list.set_offset( 0 );
        res = list.alloc_space( count );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        res = card.elem_list( list );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        for ( int i = 0; i < count; ++i )
        {
            controls += controlForId( list, i );
        }
        return controls;
    }

    public void setAllMixerControls( MixerControl[] controls ) throws SoundError
    {
        ElemList list;
        int res = ElemList.alloc( out list );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        res = card.elem_list( list );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        var count = list.get_count();

        if ( count != controls.length )
            throw new SoundError.NOT_ENOUGH_CONTROLS( "Expected %u, got %u".printf( count, controls.length ) );

        list.set_offset( 0 );
        res = list.alloc_space( count );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        res = card.elem_list( list );
        if ( res < 0 )
            throw new SoundError.DEVICE_ERROR( "%s".printf( Alsa.strerror( res ) ) );

        for ( int i = 0; i < count; ++i )
        {
            setControlForId( list, i, controls[i] );
        }
    }
}

/**
 * @class FsoFramework.MixerControl
 **/
public class FsoFramework.MixerControl
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
        return infoline;
    }
}

/**
 * @class FsoFramework.SoundScenario
 *
 * A sound scenario is just a bunch of mixer controls
 **/
public abstract class FsoFramework.SoundScenario : GLib.Object
{
    
}

