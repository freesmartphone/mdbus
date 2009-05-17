/* 
 * sharing.vala
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
using Sharing;
using Posix;
using PosixExtra;

public class ConnectionSharing : FsoFramework.Network.ConnectionSharing, FsoFramework.AbstractObject
{
    private FsoFramework.Subsystem subsystem;
    private List<string> ifaces = new List<string>();
    private const string NETWORK_CLASS = "/sys/class/net";

    public ConnectionSharing( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;
        this.subsystem.registerServiceName( FsoFramework.Network.ServiceDBusName );
        this.subsystem.registerServiceObject( FsoFramework.Network.ServiceDBusName, 
                                              FsoFramework.Network.NetworkServicePath, this );

        Idle.add(this.sync);
    }


    public override string repr()
    {
        return "<FsoFramework.Network.ConnectionSharing @ %s>".printf( FsoFramework.Network.NetworkServicePath );
    }


    private bool sync()
    {
        try {
            GLib.Dir sysclass_dir = GLib.Dir.open( NETWORK_CLASS );
            this.ifaces = null;
            string iface = sysclass_dir.read_name();
            while ( iface != null )
            {
                this.ifaces.append( iface );
                iface = sysclass_dir.read_name();
            }

        }
        catch (GLib.FileError error) {
            logger.warning(error.message);
        }
        return false;
    }


    public void StartConnectionSharingWithInterface( string iface )
    {
        this.sync();
        string ip = Sharing.get_ip( iface );
        logger.info ("Hang on. Work in progress. %s".printf( ip ));
    }

}


ConnectionSharing instance;

public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new ConnectionSharing( subsystem );
    return "fsodevice.sharing";
}


[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "connection sharing fso_register_function()" );
}
