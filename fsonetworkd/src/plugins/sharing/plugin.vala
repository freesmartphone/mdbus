/*
 * plugin.vala
 * Written by Sudharshan "Sup3rkiddo" S <sudharsh@gmail.com>
 * All Rights Reserved
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
 */


using GLib;

namespace Sharing
{

public class ConnectionSharing : FreeSmartphone.Network, FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;

    private const string IP_FORWARD    = "/proc/sys/net/ipv4/ip_forward";
    private const string ETC_RESOLV_CONF = "/etc/resolv.conf";
    private const string ETC_UDHCPD_CONF = "/etc/udhcpd.conf";

    public ConnectionSharing( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;
        this.subsystem.registerServiceName( FsoFramework.Network.ServiceDBusName );
        this.subsystem.registerServiceObject( FsoFramework.Network.ServiceDBusName, 
                                              FsoFramework.Network.ServicePathPrefix, this );
    }

    public override string repr()
    {
        return "<%s>".printf( FsoFramework.Network.ServicePathPrefix );
    }

    private string get_nameservers()
    {
        File file = File.new_for_path( ETC_RESOLV_CONF );
        var nameservers = "";
        DataInputStream stream = new DataInputStream( file.read(null) );

        try
        {
            var line = stream.read_line( null, null );
            while (( line = stream.read_line( null, null ) ) != null)
            {
                if ( line == "\n" || line == "" )
                    continue;

                if ( "nameserver" in line )
                {
                    string[] _list = line.split(" ");
                    if ( (_list[1] != "") && (_list[0] != "") )
                        nameservers = nameservers + " " + _list[1];

                }
            }
        }
        catch ( GLib.Error e ) {
            logger.warning( e.message );
        }
        return nameservers;
    }


    //
    // DBUS API
    //
    public void start_connection_sharing_with_interface( string iface ) throws FreeSmartphone.Error, DBus.Error
    {
        if ( !(FsoFramework.FileHandling.isPresent( Path.build_filename( sys_class_net, iface ) ) ) )
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Interface %s not present".printf( iface ) );

        string ip = FsoFramework.Network.ipv4AddressForInterface( iface );
        if (ip == "")
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Interface %s not ready".printf( iface ) );

        string[] commands = {
            "iptables -I INPUT 1 -s 192.168.0.0/24 -j ACCEPT",
            "iptables -I OUTPUT 1 -s %s -j ACCEPT".printf( ip ),
            "iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.0.0/24"
        };

        try
        {
            foreach( string command in commands )
            {
                Process.spawn_command_line_async( command );
                logger.debug( "executing %s".printf( command ) );
            }
            FsoFramework.FileHandling.write( "1", IP_FORWARD );

            string nameservers = get_nameservers();
            FsoFramework.FileHandling.write( UDHCPD_TEMPLATE.printf( iface, nameservers, ip ), ETC_UDHCPD_CONF );

            /* Re-launch udhcpd */
            Process.spawn_command_line_async( "killall udhcpd" );
            Process.spawn_command_line_async( "udhcpd" );
        }
        catch ( GLib.SpawnError e )
        {
            logger.warning( e.message );
        }
    }

}

private const string UDHCPD_TEMPLATE = """# freesmartphone.org /etc/udhcpd.conf
start           192.168.0.20  # lease range
end             192.168.0.199 # lease range
interface       %s            # listen on interface
option dns      %s            # grab from resolv.conf
option  subnet  255.255.255.0
opt     router  %s            # address of interface
option  lease   864000        # 10 days of seconds""";

} /* end namespace */


static string sys_class_net;
Sharing.ConnectionSharing instance;

public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    // grab sysfs and dev paths
    var config = FsoFramework.theMasterKeyFile();
    var sysfs_root = config.stringValue( "cornucopia", "sysfs_root", "/sys" );
    sys_class_net = "%s/class/net".printf( sysfs_root );
    // create instance
    instance = new Sharing.ConnectionSharing( subsystem );
    return "fsonetwork.sharing";
}


[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "connection sharing fso_register_function()" );
}
