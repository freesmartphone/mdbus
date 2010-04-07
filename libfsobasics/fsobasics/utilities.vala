/*
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

internal const uint READ_BUF_SIZE = 1024 * 1024;
internal const int BACKTRACE_SIZE = 50;

internal static string _hardware = null;
internal static string _prefix = null;
internal static string _program = null;

internal static GLib.Regex _keyValueRe = null;

namespace FsoFramework { namespace FileHandling {

public bool createDirectory( string filename, Posix.mode_t mode )
{
	return ( Posix.mkdir( filename, mode ) != -1 );
}

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

public string readIfPresent( string filename )
{
    return isPresent( filename ) ? read( filename ) : "";
}

public string read( string filename )
{
    char[] buf = new char[READ_BUF_SIZE];

    var fd = Posix.open( filename, Posix.O_RDONLY );
    if ( fd == -1 )
    {
        FsoFramework.theLogger.warning( @"Can't read-open $filename: $(Posix.strerror(Posix.errno))" );
    }
    else
    {
        ssize_t count = Posix.read( fd, buf, READ_BUF_SIZE );
        if ( count < 1 )
        {
            FsoFramework.theLogger.warning( @"Couldn't read anything from $filename: $(Posix.strerror(Posix.errno))" );
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
        FsoFramework.theLogger.warning( @"Can't write-open $filename: $(Posix.strerror(Posix.errno))" );
    }
    else
    {
        var length = contents.len();
        ssize_t written = Posix.write( fd, contents, length );
        if ( written != length )
        {
            FsoFramework.theLogger.warning( @"Couldn't write all bytes to $filename ($written of $length)" );
        }
        Posix.close( fd );
    }
}

public uint8[] readContentsOfFile( string filename ) throws GLib.FileError
{
    Posix.Stat structstat;
    var ok = Posix.stat( filename, out structstat );
    if ( ok != 0 )
    {
        throw new GLib.FileError.FAILED( Posix.strerror(Posix.errno) );
    }

    var fd = Posix.open( filename, Posix.O_RDONLY );
    if ( fd != 0 )
    {
        throw new GLib.FileError.FAILED( Posix.strerror(Posix.errno) );
    }

    var buf = new uint8[structstat.st_size];
    var bread = Posix.read( fd, buf, structstat.st_size );
    if ( bread != structstat.st_size )
    {
        Posix.close( fd );
        throw new GLib.FileError.FAILED( @"Short read; got only $bread of $(structstat.st_size)" );
    }

    Posix.close( fd );
    return buf;
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
        FsoFramework.theLogger.warning( @"Can't write-open $filename: $(Posix.strerror(Posix.errno))" );
    }
    else
    {
        ssize_t written = Posix.write( fd, buffer, length );
        if ( written != length )
        {
            FsoFramework.theLogger.warning( @"Couldn't write all bytes to $filename ($written of $length)" );
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

public GLib.HashTable<string,string> splitKeyValuePairs( string str )
{
    var result = new GLib.HashTable<string,string>( GLib.str_hash, GLib.str_equal );
    if ( _keyValueRe == null )
    {
        _keyValueRe = new GLib.Regex( "(?P<key>[A-Za-z0-9]+)=(?P<value>[A-Za-z0-9.]+)" );
    }
    GLib.MatchInfo mi;
    var next = _keyValueRe.match( str, GLib.RegexMatchFlags.NEWLINE_CR, out mi );
    while ( next )
    {
        //debug( "got match '%s' = '%s'", mi.fetch_named( "key" ), mi.fetch_named( "value" ) );
        result.insert( mi.fetch_named( "key" ), mi.fetch_named( "value" ) );
        next = mi.next();
    }
    return result;
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
        void* buffer = malloc0( BACKTRACE_SIZE * sizeof(string) );
        var size = Linux.backtrace( buffer, BACKTRACE_SIZE );
        string[] symbols = Linux.backtrace_symbols( buffer, size );
        result += "--- BACKTRACE (%zd frames) ---\n".printf( size );
        for ( var i = 0; i < size; ++i )
        {
            result += "%s\n".printf( symbols[i] );
        }
        result += "--- END BACKTRACE ---\n";
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
            }
        }
        return _hardware;
    }

    public string machineConfigurationDir()
    {
        //FIXME: Don't hardcode
        return @"/etc/freesmartphone/conf/$(hardware())";
    }
} }

namespace FsoFramework { namespace Async {

    /**
     * @class EventFd
     **/
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

    /**
     * @class ReactorChannel
     **/
    public class ReactorChannel
    {
        public delegate void ActionFunc( void* data, ssize_t length );
        private int fd;
        private uint watch;
        private GLib.IOChannel channel;
        private ActionFunc actionfunc;
        private char[] buffer;
        private size_t bufferlength;

        public ReactorChannel( int fd, owned ActionFunc actionfunc, size_t bufferlength = 512 )
        {
            assert( fd > -1 );
            channel = new GLib.IOChannel.unix_new( fd );
            watch = channel.add_watch( GLib.IOCondition.IN | GLib.IOCondition.HUP, onActionFromChannel );
            this.fd = fd;
            this.actionfunc = actionfunc;
            buffer = new char[ bufferlength ];
        }

        public int fileno()
        {
            return fd;
        }

        //
        // private API
        //
        ~ReactorChannel()
        {
            channel = null;
            GLib.Source.remove( watch );
            Posix.close( fd );
        }

        private bool onActionFromChannel( GLib.IOChannel source, GLib.IOCondition condition )
        {
            if ( ( condition & IOCondition.HUP ) == IOCondition.HUP )
            {
                // On exceptional condition, the delegate is being called with (null, 0) to do
                // whatever necessary to bring us back on track.
                actionfunc( null, 0 );
                return false;
            }

            if ( ( condition & IOCondition.IN ) == IOCondition.IN )
            {
                assert( fd != -1 );
                assert( buffer != null );
                ssize_t bytesread = Posix.read( fd, buffer, buffer.length );
                actionfunc( buffer, bytesread );
                return true;
            }

            FsoFramework.theLogger.error( "Unsupported IOCondition %u".printf( (int)condition ) );
            return true;
        }
    }
} }
