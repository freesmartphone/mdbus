/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace FsoFramework.Async
{
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
    public class ReactorChannel : GLib.Object
    {
        public delegate void ActionFunc( void* data, ssize_t length );
        private int fd;
        private uint watch;
        private GLib.IOChannel channel;
        private ActionFunc actionfunc;
        private char[] buffer;
        private bool rewind_flag;

        private void init( int fd, owned ActionFunc actionfunc, size_t bufferlength = 512 )
        {
            assert( fd > -1 );
            channel = new GLib.IOChannel.unix_new( fd );
            assert( channel != null );
            this.fd = fd;
            this.actionfunc = actionfunc;
            buffer = new char[ bufferlength ];
        }

        public ReactorChannel( int fd, owned ActionFunc actionfunc, size_t bufferlength = 512 )
        {
            init( fd, actionfunc, bufferlength );
            watch = channel.add_watch( GLib.IOCondition.IN | GLib.IOCondition.HUP, onActionFromChannel );
            this.rewind_flag = false;
        }

        public ReactorChannel.rewind( int fd, owned ActionFunc actionfunc, size_t bufferlength = 512 )
        {
            init( fd, actionfunc, bufferlength );
            watch = channel.add_watch( GLib.IOCondition.IN | GLib.IOCondition.PRI | GLib.IOCondition.HUP, onActionFromChannel );
            this.rewind_flag = true;
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

            if ( ( ( condition & IOCondition.IN  ) == IOCondition.IN  ) ||
                 ( ( condition & IOCondition.PRI ) == IOCondition.PRI ) )
            {
                assert( fd != -1 );
                assert( buffer != null );
                if( rewind_flag ) Posix.lseek(fd, 0, Posix.SEEK_SET);
                ssize_t bytesread = Posix.read( fd, buffer, buffer.length );
                actionfunc( buffer, bytesread );
                return true;
            }

            FsoFramework.theLogger.error( "Unsupported IOCondition %u".printf( (int)condition ) );
            return true;
        }
    }

    public async void sleep_async( int timeout, GLib.Cancellable? cancellable = null )
    {
        ulong cancel = 0;
        uint timeout_src = 0;
        bool interrupted = false;
        if( cancellable != null )
        {
            if ( cancellable.is_cancelled() )
                return;
            cancel = cancellable.cancelled.connect( () =>
                {
                    interrupted = true;
                    sleep_async.callback();
                } );
        }

        timeout_src = Timeout.add( timeout, sleep_async.callback );
        yield;
        Source.remove (timeout_src);

        if (cancel != 0 && ! interrupted)
        {
            cancellable.disconnect( cancel );
        }
    }
}

