using Alsa;

int main( string[] args )
{
    message( "alsa test starting" );

    Card card;

    int res = Card.open( out card, args.length > 1 ? args[1] : "default" );
    message( "card open: %s", Alsa.strerror( res ) );
    if (res < 0)
        return -1;

    CardInfo info;
    res = CardInfo.alloc( out info );
    message( "cardinfo alloc: %s", Alsa.strerror( res ) );
    if (res < 0)
        return -1;

    ElemList list;
    res = ElemList.alloc( out list );
    message( "elemlist alloc: %s", Alsa.strerror( res ) );
    if (res < 0)
        return -1;

    res = card.card_info( info );
    message( "card card_info: %s", Alsa.strerror( res ) );
    if (res < 0)
        return -1;

    message( "Card '%s' / '%s'", info.get_id(), info.get_longname() );
    message( "Mixer '%s'", info.get_mixername() );
    message( "Components '%s'", info.get_components() );

    /*

    res = card.elem_list( list );
    message( "card elem_list: %s", Alsa.strerror( res ) );
    if (res < 0)
        return -1;

    var count = list.get_count();
    message( "card elem_list has %u elements (%u used)", count, list.get_used() );

    list.set_offset( 0 );
    res = list.alloc_space( count );
    message( "elemlist alloc_space: %s", Alsa.strerror( res ) );

    if (res < 0)
        return -1;

    for ( int i = 0; i < count; ++i )
    {
        ElemId eid;
        ElemId.alloc( out eid );
        list.get_id( i, eid );
        message( "querying control #%d - name: %s", i, eid.get_name() );
    }

    list.free_space();

    */

    Mixer mixer;
    res = Mixer.open( out mixer );
    message( "mixer open: %s", Alsa.strerror( res ) );
    if (res < 0)
        return -1;

    res = mixer.attach( args.length > 1 ? args[1] : "default" );
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

    return 0;
}

