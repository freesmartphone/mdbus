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

namespace FsoFramework { namespace FileHandling {

//Logger logger = createLogger( "utilities" );

const uint READ_BUF_SIZE = 1024;

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

public void write( string contents, string filename )
{
    var fd = Posix.open( filename, Posix.O_WRONLY );
    if ( fd == -1 )
    {
        warning( "%s", "can't open for writing to %s: %s".printf( filename, Posix.strerror( Posix.errno ) ) );
    }
    else
    {
        var length = contents.len();
        ssize_t written = Posix.write( fd, contents, length );
        if ( written != length )
            warning( "couldn't write all bytes" );
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

} }

namespace FsoFramework { namespace Utility {

    const uint BUF_SIZE = 1024; // should be Posix.PATH_MAX

    public string programName()
    {
        string res = GLib.Environment.get_prgname();
        if ( res != null )
            return res;

        char[] buf = new char[BUF_SIZE];
        var length = Posix.readlink( "/proc/self/exe", buf );
        buf[length] = 0;
        assert( length != 0 );
        return GLib.Path.get_basename( (string) buf );
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
            channel = new GLib.IOChannel.unix_new( Linux26.eventfd( initvalue, 0 ) );
            watch = channel.add_watch( GLib.IOCondition.IN, callback );
        }

        public void write( int count )
        {
            Linux26.eventfd_write( channel.unix_get_fd(), count );
        }

        public uint read()
        {
            uint64 result;
            Linux26.eventfd_read( channel.unix_get_fd(), out result );
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
