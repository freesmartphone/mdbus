using Alsa;
using GLib;

Card card;
FileStream stream;
string command;

void dump_control( ElemId eid )
{
    ElemInfo info;
    ElemInfo.alloc( out info );
    info.set_id( eid );
    card.elem_info( info );

    ElemValue value;
    ElemValue.alloc( out value );
    value.set_id( eid );
    card.elem_read( value );

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
        default:
            for ( var i = 0; i < count; ++i )
                infoline += "???,";
            break;
    }
    stream.printf( "%s\n", infoline );
}

void set_control( ElemId eid, string[] params )
{
    ElemInfo info;
    ElemInfo.alloc( out info );
    info.set_id( eid );
    card.elem_info( info );

    ElemValue value;
    ElemValue.alloc( out value );
    value.set_id( eid );
    card.elem_read( value );

    var type = info.get_type();
    var count = info.get_count();

    switch (type)
    {
        case ElemType.BOOLEAN:
            for ( var i = 0; i < count; ++i )
                value.set_boolean( i, params[i] == "1" );
            break;
        case ElemType.INTEGER:
            for ( var i = 0; i < count; ++i )
                value.set_integer( i, params[i].to_int() );
            break;
        case ElemType.INTEGER64:
            for ( var i = 0; i < count; ++i )
                value.set_integer( i, params[i].to_long() );
            break;
        case ElemType.ENUMERATED:
            for ( var i = 0; i < count; ++i )
                value.set_enumerated( i, params[i].to_int() );
            break;
        case ElemType.BYTES:
            for ( var i = 0; i < count; ++i )
                value.set_byte( i, (uchar) params[i].to_int() );
            break;
        default:
            // ignoring
            break;
    }

    var res = card.elem_write( value );
    message( "card elem_write: %s", Alsa.strerror( res ) );
}

int main( string[] args )
{
    if ( args.length != 4 || ( args[2] != "dump" ) && ( args[2] != "set" ) )
    {
        stdout.printf( "Usage: %s <card> <dump|set> <filename>\n".printf( args[0] ) );
        return 1;
    }

    command = args[2];

    int res = Card.open( out card, args[1] );
    message( "card open: %s", Alsa.strerror( res ) );
    assert (res >= 0 );

    CardInfo info;
    res = CardInfo.alloc( out info );
    message( "cardinfo alloc: %s", Alsa.strerror( res ) );
    assert (res >= 0 );

    ElemList list;
    res = ElemList.alloc( out list );
    message( "elemlist alloc: %s", Alsa.strerror( res ) );
    assert (res >= 0 );

    res = card.card_info( info );
    message( "card card_info: %s", Alsa.strerror( res ) );
    assert (res >= 0 );

    message( "Card '%s' / '%s'", info.get_id(), info.get_longname() );
    message( "Mixer '%s'", info.get_mixername() );
    message( "Components '%s'", info.get_components() );

    res = card.elem_list( list );
    message( "card elem_list: %s", Alsa.strerror( res ) );
    assert (res >= 0 );

    var count = list.get_count();
    message( "card elem_list has %u elements (%u used)", count, list.get_used() );

    list.set_offset( 0 );
    res = list.alloc_space( count );
    message( "elemlist alloc_space: %s", Alsa.strerror( res ) );
    assert (res >= 0 );

    res = card.elem_list( list );
    message( "card elem_list: %s", Alsa.strerror( res ) );
    assert (res >= 0 );

    char[] buf;
    buf = new char[512];

    if ( command == "set" )
    {
        stream = FileStream.open( args[3], "r" );
        assert( stream != null );
        for( int i = 0; i < count; ++i )
        {
            var line = stream.gets( buf );
            var segments = line.split( ":" );
            assert( segments.length == 4 );
            uint idx = segments[0].to_int();
            string name = segments[1].replace( "'", "" );
            uint elements = segments[2].to_int();
            var params = segments[3].strip().split( "," );
            message( "%u:'%s':%u:'%s'", idx, name, elements, segments[3] );

            ElemId eid;
            ElemId.alloc( out eid );
            list.get_id( i, eid );
            set_control( eid, params );
        }
    }
    else
    {
        stream = FileStream.open( args[3], "w" );

        for ( int i = 0; i < count; ++i )
        {
            ElemId eid;
            ElemId.alloc( out eid );
            list.get_id( i, eid );
            dump_control( eid );
        }

    }
    list.free_space();

    //
    // SIMPLE API
    //

    /*

    Mixer mixer;
    res = Mixer.open( out mixer );
    message( "mixer open: %s", Alsa.strerror( res ) );
    if (res < 0)
        return -1;

    res = mixer.attach( args[1] );
    message( "mixer attach: %s", Alsa.strerror( res ) );
    if (res < 0)
        return -1;

    res = mixer.selem_register();
    message( "mixer selem_register: %s", Alsa.strerror( res ) );
    if (res < 0)
        return -1;

    res = mixer.load();
    message( "mixer load: %s", Alsa.strerror( res ) );
    if (res < 0)
        return -1;

    var mcount = mixer.get_count();
    message( "mixer get_count: %u", mcount );

    for ( var me = mixer.first_elem(); me != null; me = me.next() )
    {
        SimpleElementId seid;
        SimpleElementId.alloc( out seid );
        me.get_id( seid );
        message( "mixer element: %s:%u", seid.get_name(), seid.get_index() );
    }

    */

    return 0;
}

// vim:ts=4:sw=4:expandtab
