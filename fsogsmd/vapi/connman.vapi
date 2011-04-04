/*
 * connman.vapi
 *
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

namespace Connman
{
    [CCode (cname = "CONNMAN_VERSION", cheader_filename = "connman/version.h")]
    public const uint VERSION;

    [CCode (has_target = false)]
    public delegate void PluginInitFunc();
    [CCode (has_target = false)]
    public delegate void PluginExitFunc();

    [CCode (has_target = false)]
    public delegate int NetworkDriverProbeFunc(Network network);
    public delegate int NetworkDriverRemoveFunc(Network network);
    public delegate int NetworkDriverConnectFunc(Network network);
    public delegate int NetworkDriverDisconnectFunc(Network network);
    public delegate int NetworkDriverSetupFunc(Network network, string key);

    [CCode (cname = "int", cprefix = "CONNMAN_NETWORK_TYPE_", has_type_id = false, cheader_filename = "connman/network.h")]
    public enum NetworkType
    {
        UNKNOWN,
        ETHERNET,
        WIFI,
        WIMAX,
        BLUETOOTH_PAN,
        BLUETOOTH_DUN,
        CELLULAR,
        VENDOR,
    }

    [CCode (cname = "int", cprefix = "CONNMAN_NETWORK_ERROR_", has_type_id = false, cheader_filename = "connman/network.h")]
    public enum NetworkError
    {
        UNKNOWN,
        ASSOCIATE_FAIL,
        CONFIGURE_FAIL,
        INVALID_KEY,
    }

    [CCode (cname = "int", cprefix = "CONNMAN_IPCONFIG_TYPE_", has_type_id = false, cheader_filename = "connman/ipconfig.h")]
    public enum IpconfigType
    {
        UNKNOWN,
        IPV4,
        IPV6
    }

    [CCode (cname = "int", cprefix = "CONNMAN_IPCONFIG_METHOD_", has_type_id = false, cheader_filename = "connman/ipconfig.h")]
    public enum IpconfigMethod
    {
        UNKNOWN,
        OFF,
        FIXED,
        MANUAL,
        DHCP,
        AUTO
    }

    [CCode (cprefix = "connman_ipaddress_", cname = "struct connman_ipaddress", free_function = "connman_ipaddress_free", cheader_filename = "connman/ipconfig.h")]
    public class IpAddress
    {
        public int family;
        public uint8 prefixlen;
        public string local;
        public string peer;
        public string broadcast;
        public string gateway;

        [CCode (cname = "connman_ipaddress_alloc")]
        public IpAddress(int family);

        public int set_ipv4(string address, string netmask, string gateway);
        public int set_ipv6(string address, string gateway, uint8 prefix_length);
        public void set_peer(string peer);
        public void clear();
    }

    [CCode (cprefix = "connman_network_", cname = "struct connman_network", cheader_filename = "connman/network.h", 
            ref_function = "connman_network_ref", unref_function = "connman_network_unref")]
    public class Network
    {
        [CCode (cname = "connman_network_create")]
        public Network(string identifier, NetworkType type);

        public NetworkType get_type();
        public string get_identifier();
        // public Element get_element();
        public void set_index(int index);
        public int get_index();
        public void set_group(string group);
        public string get_group();
        public bool get_connecting();
        public int set_available(bool available);
        public bool get_available();
        public int set_associating(bool associating);
        public void set_error(NetworkError error);
        public void clear_error();
        public int set_connected(bool connected);
        public bool get_connected();
        public bool get_associating();
        public void set_ipv4_method(IpconfigMethod method);
        public void set_ipv6_method(IpconfigMethod method);
        public int set_ipaddress(IpAddress address);
        public int set_nameservers(string nameservers);
        public int set_domain(string domain);
        public int set_pac(string domain);
        public int set_name(string name);
        public int set_strength(uint8 strength);
        public int set_roaming(bool roaming);
        public int set_string(string key, string value);
        public string get_string(string key);
        public int set_bool(string key, bool value);
        public bool get_bool(string key);
        public int set_uint8(string key, uint8 value);
        public uint8 get_uint8(string key);
        public int set_uint16(string key, uint16 value);
        public uint8 get_uint16(string key);
        public int set_blob(string key, void *value, uint size);
        public void* get_blob(string key, out uint size);
        // public Device get_device();
        public void* get_data();
        public void set_data(void *data);
        public void update();
    }

    [Compact]
    [CCode (cname = "struct connman_network_driver", cheader_filename = "connman/network.h", free_function = "")]
    public class NetworkDriver
    {
        public string name;
        public NetworkType type;
        public int priority;
        public NetworkDriverProbeFunc probe;
        public NetworkDriverRemoveFunc remove;
        public NetworkDriverConnectFunc connect;
        public NetworkDriverDisconnectFunc disconnet;
        public NetworkDriverSetupFunc setup;

        public NetworkDriver(string name, NetworkType type)
        {
            this.name = name;
            this.type = type;
        }

        [CCode (cname = "connman_network_driver_register")]
        public int register();
        [CCode (cname = "connman_network_driver_unregister")]
        public void unregister();
    }
}
