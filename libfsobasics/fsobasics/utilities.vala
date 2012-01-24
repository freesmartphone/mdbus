/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

internal const string PROC_SELF_CMDLINE = "/proc/self/cmdline";
internal const string PROC_SELF_EXE     = "/proc/self/exe";
internal const string PROC_CPUINFO      = "/proc/cpuinfo";

internal const int BACKTRACE_SIZE = 50;

internal static string _hardware = null;
internal static string _prefix = null;
internal static string _program = null;

internal static GLib.HashTable<string,void*> _hashtable = null;

namespace FsoFramework.DataSharing
{
    public void setValueForKey( string key, void* val )
    {
        if ( _hashtable == null )
        {
            _hashtable = new GLib.HashTable<string,void*>( GLib.str_hash, GLib.str_equal );
        }
        _hashtable.insert( key, val );
    }

    public void* valueForKey( string key )
    {
        if ( _hashtable == null )
        {
            _hashtable = new GLib.HashTable<string,void*>( GLib.str_hash, GLib.str_equal );
        }
        return _hashtable.lookup( key );
    }
}

namespace FsoFramework.UserGroupHandling
{
    public Posix.uid_t uidForUser( string user )
    {
        Posix.setpwent();
        unowned Posix.Passwd pw = Posix.getpwent();
        while ( pw != null )
        {
            if ( pw.pw_name == user )
                return pw.pw_uid;
            pw = Posix.getpwent();
        }
        return -1;
    }

    public Posix.gid_t gidForGroup( string group )
    {
        Posix.setgrent();
        unowned Posix.Group gr = Posix.getgrent();
        while ( gr != null )
        {
            if ( gr.gr_name == group )
                return gr.gr_gid;
            gr = Posix.getgrent();
        }
        return -1;
    }

    public bool switchToUserAndGroup( string user, string group )
    {
        var uid = uidForUser( user );
        var gid = gidForGroup( group );
        if ( uid == -1 || gid == -1 )
            return false;
        var ok = Posix.setgid( gid );
        if ( ok != 0 )
        {
            FsoFramework.theLogger.warning( @"Can't set group id: $(Posix.strerror(Posix.errno))" );
            return false;
        }
        ok = Posix.setuid( uid );
        if ( ok != 0 )
        {
            FsoFramework.theLogger.warning( @"Can't set user id: $(Posix.strerror(Posix.errno))" );
            return false;
        }
        return true;
    }
}

namespace FsoFramework.Utility
{
    const uint BUF_SIZE = 1024; // should be Posix.PATH_MAX

    public string programName()
    {
        if ( _program == null )
        {

            _program = GLib.Environment.get_prgname();
            if ( _program == null )
            {
                char[] buf = new char[BUF_SIZE];
                var length = Posix.readlink( PROC_SELF_EXE, buf );
                buf[length] = 0;
                assert( length != 0 );
                _program = GLib.Path.get_basename( (string) buf );
            }
        }
        return _program;
    }

    public string prefixForExecutable()
    {
        if ( _prefix == null )
        {
            var cmd = FileHandling.read( PROC_SELF_CMDLINE );
            var pte = Environment.find_program_in_path( cmd );
            _prefix = "";

            foreach ( var component in pte.split( "/" ) )
            {
                //debug( "dealing with component '%s', prefix = '%s'", component, _prefix );
                if ( component.has_suffix( "bin" ) )
                    break;
                _prefix += "%s%c".printf( component, Path.DIR_SEPARATOR );
            }
        }
        return _prefix;
    }

    public string[] createBacktrace()
    {
        string[] result = new string[] { };
#if HAVE_BACKTRACE
        void* buffer = malloc0( BACKTRACE_SIZE * sizeof(string) );
        var size = Linux.backtrace( buffer, BACKTRACE_SIZE );
        string[] symbols = Linux.backtrace_symbols( buffer, size );
        result += "--- BACKTRACE (%zd frames) ---\n".printf( size );
        for ( var i = 0; i < size; ++i )
        {
            result += "%s\n".printf( symbols[i] );
        }
        result += "--- END BACKTRACE ---\n";
#else
        result += "BACKTRACE FACILITIES NOT AVAILABLE";
#endif
        return result;
    }

    public string? firstAvailableProgram( string[] candidates )
    {
        for ( int i = 0; i < candidates.length; ++i )
        {
            var pte = Environment.find_program_in_path( candidates[i] );
            if ( pte != null )
            {
                return pte;
            }
        }
        return null;
    }

    public string hardware()
    {
        if ( _hardware != null )
        {
            return _hardware;
        }
        _hardware = "default";

        var proc_cpuinfo = FsoFramework.FileHandling.read( PROC_CPUINFO );
        if ( proc_cpuinfo != "" )
        {
            foreach ( var line in proc_cpuinfo.split( "\n" ) )
            {
                if ( line.has_prefix( "Hardware" ) )
                {
                    var parts = line.split( ": " );
                    _hardware = ( parts.length == 2 ) ? parts[1].strip().replace( " ", "" ) : "unknown";
                    break;
                }
                if ( line.has_prefix( "vendor_id" ) )
                {
                    var parts = line.split( ": " );
                    _hardware = ( parts.length == 2 ) ? parts[1].strip().replace( " ", "" ) : "unknown";
                    break;
                }
            }
        }
        return _hardware;
    }

    public string machineConfigurationDir()
    {
        return Path.build_filename( Config.SYSCONFDIR, "freesmartphone", "conf", hardware() );;
    }
    public string dataToString(uint8[] data, int limit = -1)
    {
        if (limit == -1 || data.length < limit)
        {
            limit = data.length;
        }

        unowned string str = (string)data;

        return str.ndup(limit);
    }

    public int copyData( ref uint8[] destination, uint8[] source, int limit = -1 )
    {
        int length = destination.length;
        if( limit >= 0 && limit < length )
             length = limit;
        if( length > source.length )
             length = source.length;
        GLib.Memory.copy( destination, source, length );

        destination.length = length;

        return length;
    }

    public T[] listToArray<T>(GLib.List<T> list)
    {
        T[] a = new T[list.length()];
        var n = 0;
        foreach ( var element in list )
        {
            a[n] = element;
            n++;
        }
        return a;
    }
}

namespace FsoFramework.Network
{
    public async string[]? textForUri( string servername, string uri = "/" ) throws GLib.Error
    {
        var result = new string[] {};

        var resolver = Resolver.get_default();
        List<InetAddress> addresses = null;
        try
        {
             addresses = yield resolver.lookup_by_name_async( servername, null );
        }
        catch ( Error e )
        {
            FsoFramework.theLogger.warning( @"Could not resolve server address $(e.message)" );
            return null;
        }
        var serveraddr = addresses.nth_data( 0 );
        assert( FsoFramework.theLogger.debug( @"Resolved $servername to $serveraddr" ) );

        var socket = new InetSocketAddress( serveraddr, 80 );
        var client = new SocketClient();
        var conn = yield client.connect_async( socket, null );

        assert( FsoFramework.theLogger.debug( @"Connected to $serveraddr" ) );

        var message = @"GET $uri HTTP/1.1\r\nHost: $servername\r\nConnection: close\r\n\r\n";
        yield conn.output_stream.write_async( message.data );
        assert( FsoFramework.theLogger.debug( @"Wrote request" ) );

        conn.socket.set_blocking( true );
        var input = new DataInputStream( conn.input_stream );

        var line = ( yield input.read_line_async( 0, null, null ) ).strip();
        assert( FsoFramework.theLogger.debug( @"Received status line: $line" ) );

        if ( ! ( line.has_prefix( "HTTP/1.1 200 OK" ) ) )
        {
            return null;
        }

        // skip headers
        while ( line != null && line != "\r" && line != "\r\n" )
        {
            line = yield input.read_line_async( 0, null, null );
            if ( line != null )
            {
                assert( FsoFramework.theLogger.debug( @"Received header line: $(line.escape( """""" ) )" ) );
            }
        }

        while ( line != null )
        {
            line = yield input.read_line_async( 0, null, null );
            if ( line != null && line != "\r" && line != "\r\n" && line != "" )
            {
                assert( FsoFramework.theLogger.debug( @"Received content line: $line" ) );
                result += line.strip();
            }
        }
        return result;
    }
}

// vim:ts=4:sw=4:expandtab
