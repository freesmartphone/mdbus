/*
 * (C) 2009-2012 Sudharshan "Sup3rkiddo" S <sudharsh@gmail.com>
 * (C) 2009-2012 Michael 'Mickey' Lauer <mickey@vanille-media.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 **/

using GLib;

namespace Sharing
{
    public const string MODULE_NAME = "fsonetwork.sharing";

    private const string UDHCPD_TEMPLATE = """# freesmartphone.org /etc/udhcpd.conf
start           192.168.0.20  # lease range
end             192.168.0.199 # lease range
interface       %s            # listen on interface
option dns      %s            # grab from resolv.conf
option  subnet  255.255.255.0
opt     router  %s            # address of interface
option  lease   864000        # 10 days of seconds""";

}

public class Sharing.ConnectionSharing : FreeSmartphone.Network, FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;

    private const string IP_FORWARD    = "/proc/sys/net/ipv4/ip_forward";
    private const string ETC_RESOLV_CONF = "/etc/resolv.conf";
    private const string ETC_UDHCPD_CONF = "/etc/udhcpd.conf";

    public ConnectionSharing( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;
        this.subsystem.registerObjectForService<FreeSmartphone.Network>( FsoFramework.Network.ServiceDBusName, FsoFramework.Network.ServicePathPrefix, this );
    }

    public override string repr()
    {
        return "<%s>".printf( FsoFramework.Network.ServicePathPrefix );
    }

    private string get_nameservers()
    {
        File file = File.new_for_path( ETC_RESOLV_CONF );
        var nameservers = "";

        try
        {
            var stream = new DataInputStream( file.read(null) );

            var line = stream.read_line( null, null );
            while (( line = stream.read_line( null, null ) ) != null)
            {
                if ( line == "\n" || line == "" )
                    continue;

                if ( "nameserver" in line )
                {
                    string[] _list = line.split(" ");
                    if ( (_list[1] != "") && (_list[0] != "") )
                    {
                        nameservers = nameservers + " " + _list[1];
                    }
                }
            }
        }
        catch ( GLib.Error e )
        {
            logger.warning( e.message );
        }
        return nameservers;
    }

    //
    // FreeSmartphone.Network (DBUS API)
    //
    public async void start_connection_sharing_with_interface( string iface ) throws FreeSmartphone.Error, DBusError, IOError
    {
        if ( ! (FsoFramework.FileHandling.isPresent( Path.build_filename( sys_class_net, iface ) ) ) )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Interface $iface not present" );
        }

        var ip = FsoFramework.Net.ipv4AddressForInterface( iface );
        if ( ip == "unknown" )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Interface $iface not configured" );
        }

        string[] commands = {
            "/usr/sbin/iptables -I INPUT  1           -s 192.168.0.0/24 -j ACCEPT",
            "/usr/sbin/iptables -I OUTPUT 1           -s %s             -j ACCEPT".printf( ip ),
            "/usr/sbin/iptables -A POSTROUTING -t nat -s 192.168.0.0/24 -j MASQUERADE"
        };

        foreach( string command in commands )
        {
            assert( logger.debug( @"executing $command" ) );
            var ok = Posix.system( command );
            if ( ok != 0 )
            {
                logger.error( @"Can't execute '$command' - error code $ok" );
                throw new FreeSmartphone.Error.SYSTEM_ERROR( @"Can't execute '$command' - error code $ok" );
            }
        }
        FsoFramework.FileHandling.write( "1", IP_FORWARD );

        string nameservers = get_nameservers();
        FsoFramework.FileHandling.write( UDHCPD_TEMPLATE.printf( iface, nameservers, ip ), ETC_UDHCPD_CONF, true );

        //FIXME: This needs to be configurable

        /* Re-launch udhcpd */
        try
        {
            Posix.system( "/usr/bin/killall udhcpd" );
            Posix.system( "/usr/sbin/udhcpd" );
        }
        catch ( GLib.SpawnError e )
        {
            // ignoring
        }
    }

    public async void stop_connection_sharing_with_interface( string iface ) throws FreeSmartphone.Error, DBusError, IOError
    {
        if ( ! (FsoFramework.FileHandling.isPresent( Path.build_filename( sys_class_net, iface ) ) ) )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Interface $iface not present" );
        }

        var ip = FsoFramework.Net.ipv4AddressForInterface( iface );
        if ( ip == "unknown" )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Interface $iface not configured" );
        }

        string[] commands = {
            "/usr/sbin/iptables -D INPUT                             -s 192.168.0.0/24 -j ACCEPT",
            "/usr/sbin/iptables -D OUTPUT                            -s %s             -j ACCEPT".printf( ip ),
            "/usr/sbin/iptables -D POSTROUTING -t nat                -s 192.168.0.0/24 -j MASQUERADE"
        };

        try
        {
            foreach( string command in commands )
            {
                assert( logger.debug( @"executing $command" ) );
                var ok = Posix.system( command );
                if ( ok != 0 )
                {
                    logger.error( @"Can't execute '$command' - error code $ok" );
                    throw new FreeSmartphone.Error.SYSTEM_ERROR( @"Can't execute '$command' - error code $ok" );
                }
            }
            FsoFramework.FileHandling.write( "0", IP_FORWARD );

            /* Stop udhcpd */
            Posix.system( "/usr/bin/killall udhcpd" );
        }
        catch ( GLib.SpawnError e )
        {
            logger.warning( e.message );
        }
    }

    public async void offer_default_route( string technology,
                                           string iface,
                                           string ipv4address,
                                           string ipv4mask,
                                           string ipv4gateway,
                                           string dns1,
                                           string dns2 ) throws FreeSmartphone.Error, DBusError, IOError
    {
        logger.info( @"Setting new default as offered by $technology: $iface=$ipv4address/$ipv4mask via $ipv4gateway" );
        // Quick and dirty, this is really just for testing and demonstration purposes
        var ok = Posix.system( @"/sbin/ifconfig $iface $ipv4address netmask $ipv4mask up" );
        if ( ok != 0 )
        {
            logger.error( @"Can't ifconfig $iface $ipv4address netmask $ipv4mask up" );
        }
        var routecmd = @"/sbin/route add default gw $ipv4gateway $iface";
        if ( ipv4gateway == "0.0.0.0" )
        {
            routecmd = @"/sbin/route add default $iface";
        }

        ok = Posix.system( routecmd );
        if ( ok != 0 )
        {
            logger.error( @"$routecmd returned error code $ok" );
        }
        FsoFramework.FileHandling.write( @"nameserver $dns1\nnameserver $dns2\n", ETC_RESOLV_CONF );
    }
}

static string sys_class_net;
Sharing.ConnectionSharing instance;

public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab sysfs and dev paths
    var config = FsoFramework.SmartKeyFile.defaultKeyFile();
    var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    sys_class_net = "%s/class/net".printf( sysfs_root );
    // create instance
    instance = new Sharing.ConnectionSharing( subsystem );
    return Sharing.MODULE_NAME;
}


[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "connection sharing fso_register_function()" );
}

// vim:ts=4:sw=4:expandtab
