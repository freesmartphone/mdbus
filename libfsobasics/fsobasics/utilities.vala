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
 **/

internal const string PROC_SELF_CMDLINE = "/proc/self/cmdline";
internal const string PROC_SELF_EXE     = "/proc/self/exe";
internal const uint READ_BUF_SIZE = 1024;
internal const int BACKTRACE_SIZE = 50;
internal static string _prefix = null;
internal static string _program = null;

namespace FsoFramework { namespace FileHandling {

//Logger logger = createLogger( "utilities" );

public bool removeTree( string path )
{
#if DEBUG
    debug( "removeTree: %s", path );
#endif
    var dir = Posix.opendir( path );
    if ( dir == null )
    {
#if DEBUG
        debug( "can't open dir: %s", path );
#endif
        return false;
    }
    for ( unowned Posix.DirEnt entry = Posix.readdir( dir ); entry != null; entry = Posix.readdir( dir ) )
    {
        if ( ( "." == (string)entry.d_name ) || ( ".." == (string)entry.d_name ) )
        {
#if DEBUG
            debug( "skipping %s", (string)entry.d_name );
#endif
            continue;
        }
#if DEBUG
        debug( "processing %s", (string)entry.d_name );
#endif
        var result = Posix.unlink( "%s/%s".printf( path, (string)entry.d_name ) );
        if ( result == 0 )
        {
#if DEBUG
            debug( "%s removed", (string)entry.d_name );
#endif
            continue;
        }
        if ( Posix.errno == Posix.EISDIR )
        {
            if ( !removeTree( "%s/%s".printf( path, (string)entry.d_name ) ) )
            {
                return false;
            }
            continue;
        }
        return false;
    }
    return true;
}

public bool isPresent( string filename )
{
    Posix.Stat structstat;
    return ( Posix.stat( filename, out structstat ) != -1 );
}

public string read( string filename )
{
    char[] buf = new char[READ_BUF_SIZE];

    var fd = Posix.open( filename, Posix.O_RDONLY );
    if ( fd == -1 )
    {
        warning( "%s", "can't open for reading to %s: %s".printf( filename, Posix.strerror( Posix.errno ) ) );
    }
    else
    {
        ssize_t count = Posix.read( fd, buf, READ_BUF_SIZE );
        if ( count < 1 )
        {
            warning( "couldn't read any bytes" );
            Posix.close( fd );
        }
        else
        {
            Posix.close( fd );
            return ( (string)buf ).strip();
        }
    }
    return "";
}

public void write( string contents, string filename, bool create = false )
{
    Posix.mode_t mode = 0;
    int flags = Posix.O_WRONLY;
    if ( create )
    {
        mode = Posix.S_IRUSR | Posix.S_IWUSR | Posix.S_IRGRP | Posix.S_IROTH;
        flags |= Posix.O_CREAT  | Posix.O_EXCL;
    }
    var fd = Posix.open( filename, flags, mode );
    if ( fd == -1 )
    {
        warning( "%s", "can't open for writing to %s: %s".printf( filename, Posix.strerror( Posix.errno ) ) );
    }
    else
    {
        var length = contents.len();
        ssize_t written = Posix.write( fd, contents, length );
        if ( written != length )
        {
            warning( "couldn't write all bytes to %s (%u of %ld)".printf( filename, (uint)written, length ) );
        }
        Posix.close( fd );
    }
}

public void writeBuffer( void* buffer, ulong length, string filename, bool create = false )
{
    Posix.mode_t mode = 0;
    int flags = Posix.O_WRONLY;
    if ( create )
    {
        mode = Posix.S_IRUSR | Posix.S_IWUSR | Posix.S_IRGRP | Posix.S_IROTH;
        flags |= Posix.O_CREAT  | Posix.O_EXCL;
    }
    var fd = Posix.open( filename, flags, mode );
    if ( fd == -1 )
    {
        warning( "Can't open for writing to %s: %s".printf( filename, Posix.strerror( Posix.errno ) ) );
    }
    else
    {
        ssize_t written = Posix.write( fd, buffer, length );
        if ( written != length )
        {
            warning( "Couldn't write all bytes to %s (%u of %lu)".printf( filename, (uint)written, length ) );
        }
        Posix.close( fd );
    }
}

} }

namespace FsoFramework { namespace UserGroupHandling {

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
        warning( "%s", "can't set group id: %s".printf( Posix.strerror( Posix.errno ) ) );
        return false;
    }
    ok = Posix.setuid( uid );
    if ( ok != 0 )
    {
        warning( "%s", "can't set user id: %s".printf( Posix.strerror( Posix.errno ) ) );
        return false;
    }
    return true;
}

} }

namespace FsoFramework { namespace StringHandling {

//TODO: make this a generic, once Vala supports it
public string stringListToString( string[] list )
{
    if ( list.length == 0 )
        return "[]";

    var res = "[ ";

    for( int i = 0; i < list.length; ++i )
    {
        res += "\"%s\"".printf( list[i] );
        if ( i < list.length-1 )
            res += ", ";
        else
            res += " ]";
    }
    return res;
}

public string enumToString( Type enum_type, int value )
{
    EnumClass ec = (EnumClass) enum_type.class_ref();
    unowned EnumValue ev = ec.get_value( value );
    return ev == null ? "Unknown Enum value for %s: %i".printf( enum_type.name(), value ) : ev.value_name;
}

} }

namespace FsoFramework { namespace Network {

    public string ipv4AddressForInterface( string iface )
    {
        var fd = Posix.socket( Posix.AF_INET, Posix.SOCK_DGRAM, 0 );
        assert( fd != -1 );

        Linux.Network.IfReq ifreq = {};
        Posix.memcpy( ifreq.ifr_name, iface, 16 );
        var ok = Posix.ioctl( fd, Linux.Network.SIOCGIFADDR, &ifreq );
        if ( ok < 0 )
            return "unknown";

        return "%s".printf( PosixExtra.inet_ntoa( ((PosixExtra.SockAddrIn*)(&ifreq.ifr_addr))->sin_addr ) );
    }

} }

namespace FsoFramework { namespace Utility {

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
                if ( component == "bin" )
                    break;
                _prefix += "%s%c".printf( component, Path.DIR_SEPARATOR );
            }
        }
        return _prefix;
    }

    public string[] createBacktrace()
    {
        string[] result = new string[] { };
#if HAVE_LINUX_BACKTRACE
        void* buffer = malloc0( BACKTRACE_SIZE * sizeof(string) );
        var size = Linux.backtrace( buffer, BACKTRACE_SIZE );
        string[] symbols = Linux.backtrace_symbols( buffer, size );
        result += "--- BACKTRACE (%zd frames) ---\n".printf( size );
        for ( var i = 0; i < size; ++i )
        {
            result += "%s\n".printf( symbols[i] );
        }
        result += "--- END BACKTRACE ---\n";
#endif
        return result;
    }
} }

namespace FsoFramework { namespace Async {

    [Compact]
    public class EventFd
    {
        public GLib.IOChannel channel;
        public uint watch;

        public EventFd( uint initvalue, GLib.IOFunc callback )
        {
            channel = new GLib.IOChannel.unix_new( Linux.eventfd( initvalue, 0 ) );
            watch = channel.add_watch( GLib.IOCondition.IN, callback );
        }

        public void write( int count )
        {
            Linux.eventfd_write( channel.unix_get_fd(), count );
        }

        public uint read()
        {
            uint64 result;
            Linux.eventfd_read( channel.unix_get_fd(), out result );
            return (uint)result;
        }

        ~EventFd()
        {
            Source.remove( watch );
            channel = null;
        }
    }

    /*
    [Compact]
    class IOChannel
    {
        public int fd;
        public uint watch;
        public GLib.IOChannel channel;
        public GLib.IOCondition condition;
        public GLib.SourceFunc callback;

        public IOChannel( int fd, GLib.IOCondition condition, GLib.SourceFunc callback )
        {
            if ( ( condition & GLib.IOCondition.IN ) == GLib.IOCondition.IN )
            {
                fd = Posix.open( fd, Posix.O_RDWR );
            }
            else
            {
                fd = Posix.open( fd, Posix.O_RDONLY );
            }

            _registerWatch();
        }

        ~IOChannel()
        {
            GLib.Source.remove( watch );
            Posix.close( fd );
        }

        public void _registerWatch()
        {
            if ( fd != -1 )
            {
                channel = GLib.IOChannel.unix_new( fd );
                channel.add_watch( fd, condition, callback );
            }
        }
    }
    */

} }
