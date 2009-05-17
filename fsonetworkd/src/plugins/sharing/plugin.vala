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

public class ConnectionSharing : FsoFramework.Network.ConnectionSharing, FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    private List<string> ifaces = new List<string>();
    private const string NETWORK_CLASS = "/sys/class/net";
    private const string IP_FORWARD    = "/proc/sys/net/ipv4/ip_forward";
    private const string ETC_RESOLV_CONF = "/etc/resolv.conf";
    private const string ETC_UDHCPD_CONF = "/etc/udhcpd.conf";

    public ConnectionSharing( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;
        this.subsystem.registerServiceName( FsoFramework.Network.ServiceDBusName );
        this.subsystem.registerServiceObject( FsoFramework.Network.ServiceDBusName, 
                                              FsoFramework.Network.NetworkServicePath, this );

        this.sync();
    }


    public override string repr()
    {
        return "<FsoFramework.Network.ConnectionSharing @ %s>".printf( FsoFramework.Network.NetworkServicePath );
    }



    public bool contains( string iface )
    {
        foreach ( string _i in this.ifaces )
            if ( _i == iface )
                return true;

        return false;
    }


    private bool sync()
    {
        try
        {
            GLib.Dir sysclass_dir = GLib.Dir.open( NETWORK_CLASS );
            int i = 0;
            string iface = sysclass_dir.read_name();
            while ( true )
            {
                if ( iface == null )
                    break;
                iface = sysclass_dir.read_name();
                this.ifaces.append( iface );
                i++;
            }

        }
        catch (GLib.FileError error) {
            logger.warning(error.message);
        }
        return false;
    }


    private string get_nameservers() 
    {
        File file = File.new_for_path( ETC_RESOLV_CONF );
        string nameservers = "";
        DataInputStream stream = new DataInputStream( file.read(null) );
        string line = new string();

        try
        {
            line = stream.read_line( null, null );
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
        catch (GLib.Error error) {
            logger.warning( error.message );
        }
        return nameservers;
    }



    /* DBus methods follow */
    public void StartConnectionSharingWithInterface( string iface )
    {
        this.sync();
        if (!( iface in this )) 
        {
            logger.warning( "No such interface %s".printf( iface ));
            return;
        }
        
        string ip = Sharing.get_ip( iface );
        if (ip == null) 
        {
            logger.warning( "%s not active".printf( iface ));
            return;
        }
        

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
                logger.debug ("executing %s".printf( command ));
            }
            FsoFramework.FileHandling.write( "1", IP_FORWARD );

            string nameservers = get_nameservers();
            FsoFramework.FileHandling.write( UDHCPD_TEMPLATE.printf( iface, nameservers, ip ), ETC_UDHCPD_CONF );
            
            /* Re-launch udhcpd */
            Process.spawn_command_line_async( "killall udhcpd" );
            Process.spawn_command_line_async( "udhcpd" );
            
        
        }
        catch( GLib.SpawnError error )
        {
            logger.warning( error.message );
        }
    }

}


private const string UDHCPD_TEMPLATE = "# freesmartphone.org /etc/udhcpd.conf\n \
start           192.168.0.20  # lease range\n \
end             192.168.0.199 # lease range\n \
interface       %s            # listen on interface\n \
option dns      %s            # grab from resolv.conf\n \
option  subnet  255.255.255.0 \n \
opt     router  %s            # address of interface\n \
option  lease   864000        # 10 days of seconds\n";

} /* end namespace */



Sharing.ConnectionSharing instance;

public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new Sharing.ConnectionSharing( subsystem );
    return "fsodevice.sharing";
}



[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "connection sharing fso_register_function()" );
}
