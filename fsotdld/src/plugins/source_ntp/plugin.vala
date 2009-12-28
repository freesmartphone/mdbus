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

using FsoTime;

namespace NetworkTimeProtocol
{
    const string DEFAULT_SERVER = "pool.ntp.org";
    const uint16 PORT = 123;
    const uint32 BASETIME = (uint32) 2208988800;

    struct TimeStamp
    {
        uint32 secs;
        uint32 usecs;
    }

    struct Packet
    {
        uint8 flags;
        uint8 stratum;
        uint8 poll;
        int8 precision;
        int root_delay;
        int root_dispersion;
        char refaddr[4];
        TimeStamp reference;
        TimeStamp originate;
        TimeStamp received;
        TimeStamp transmit;
    } /* size == 48 */
}

class Source.Ntp : FsoTime.AbstractSource
{
    const string MODULE_NAME = "fsotdl.source_ntp";

    private string servername;
    private InetAddress serveraddr;
    private Socket socket;

    private IOChannel channel;
    private uint watch;

    private NetworkTimeProtocol.Packet request;
    private NetworkTimeProtocol.Packet packet;

    construct
    {
        servername = config.stringValue( MODULE_NAME, "server", NetworkTimeProtocol.DEFAULT_SERVER );
        request = NetworkTimeProtocol.Packet() { flags = 0x1b };
        packet = NetworkTimeProtocol.Packet();
        assert( 48 == sizeof( NetworkTimeProtocol.Packet ) );

        Idle.add( () => { triggerQuery(); return false; } );
    }

    public override string repr()
    {
        return ( serveraddr == null ) ? "<unknown>" : @"<$serveraddr>";
    }

    public override void triggerQuery()
    {
        if ( serveraddr == null )
        {
            var resolver = Resolver.get_default();
            List<InetAddress> addresses = null;
            try
            {
                 addresses = resolver.lookup_by_name( servername, null );
            }
            catch ( GLib.Error e )
            {
                logger.warning( @"Could not resolve NTP server address $(e.message). Will try again next time." );
                return;
            }
            serveraddr = addresses.nth_data( 0 );
            assert( logger.debug( @"Resolved $servername to $serveraddr" ) );

            socket = new Socket( SocketFamily.IPV4, SocketType.DATAGRAM, SocketProtocol.UDP );
        }

        var targetaddr = new InetSocketAddress( serveraddr, NetworkTimeProtocol.PORT );
	    var sent = socket.send_to( targetaddr, (string)(&request), sizeof( NetworkTimeProtocol.Packet ), null );
	    assert( logger.debug( @"Sent $sent bytes to socket to request NTP timestamp." ) );

        channel = new IOChannel.unix_new( socket.fd );
        watch = channel.add_watch( IOCondition.IN | IOCondition.HUP, onIncomingSocketData );
    }

    private bool onIncomingSocketData( IOChannel source, IOCondition condition )
    {
        assert( logger.debug( "onIncomingSocketData called with condition = %d".printf( condition ) ) );

        if ( ( condition & IOCondition.HUP ) == IOCondition.HUP )
        {
            logger.warning( "HUP from NTP socket" );
            return false;
        }

        if ( ( condition & IOCondition.IN ) == IOCondition.IN )
        {
      	    unowned SocketAddress reply_address;
            var received = socket.receive_from( out reply_address, (string)(&packet), sizeof( NetworkTimeProtocol.Packet ), null );
            assert( logger.debug( @"Received $received bytes from socket." ) );
            Idle.add( handleUpdatePacket );
            return true;
        }

        logger.warning( "onIncomingSocketData called with unknown condition %d".printf( condition ) );
        return false;
    }

    private bool handleUpdatePacket()
    {
        uint32 tempstmp = Posix.ntohl( packet.transmit.secs );
        uint32 tempfrac = Posix.ntohl( packet.transmit.usecs );

        time_t temptime = tempstmp - NetworkTimeProtocol.BASETIME;

        this.reportTime( (int)temptime, this ); // SIGNAL

        // the rest is just for debugging
        var bd = Time.gm( temptime );
        var fractime = bd.second + tempfrac / 4294967296.0;

        logger.info( "NTP: %04d-%02d-%02d %02d:%02d:%07.4f UTC".printf(
            bd.year + 1900,
            bd.month,
            bd.day,
            bd.hour,
			bd.minute,
            fractime ) );

        return false;
    }

}

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    debug( "fsotdl.source_ntp fso_factory_function" );
    return Source.Ntp.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "fsotdl.source_ntp fso_register_function" );
    // do not remove this function
}

/**
 * This function gets called on plugin load time.
 * @return false, if the plugin operating conditions are present.
 * @note Some versions of glib contain a bug that leads to a SIGSEGV
 * in g_module_open, if you return true here.
 **/
/*public static bool g_module_check_init( void* m )
{
    var ok = FsoFramework.FileHandling.isPresent( Kernel26.SYS_CLASS_LEDS );
    return (!ok);
}
*/
