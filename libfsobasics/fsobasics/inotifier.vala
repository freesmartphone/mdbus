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

using GLib;

public delegate void FsoFramework.INotifyNotifierFunc( Linux.InotifyMaskFlags flags, uint32 cookie, string? name );

[Compact]
internal class INotifyDelegateHolder
{
    public FsoFramework.INotifyNotifierFunc func;
    public INotifyDelegateHolder( FsoFramework.INotifyNotifierFunc func )
    {
        this.func = func;
    }
}

/**
 * @class FsoFramework.INotifier
 **/
public class FsoFramework.INotifier : Object
{
    public static INotifier instance;

    private HashTable<int,INotifyDelegateHolder> delegates;

    private int fd = -1;
    private uint watch;
    private IOChannel channel;

    private char[] buffer;

    private const ssize_t BUFFER_LENGTH = 4096;

    public INotifier()
    {
        buffer = new char[BUFFER_LENGTH];
        delegates = new HashTable<int,INotifyDelegateHolder>( direct_hash, direct_equal );

        fd = Linux.inotify_init();
        if ( fd == -1 )
        {
            FsoFramework.theLogger.error( @"Can not init the inotify subsystem: $(strerror(errno)); some features will not work" );
            return;
        }
        channel = new IOChannel.unix_new( fd );
        watch = channel.add_watch( IOCondition.IN | IOCondition.HUP, onActionFromInotify );
#if DEBUG
        debug( "inotifier created" );
#endif
    }

    ~INotifier()
    {
        if ( watch != 0 )
            Source.remove( watch );

        if ( fd != -1 )
            Posix.close( fd );
    }

    protected bool onActionFromInotify( IOChannel source, IOCondition condition )
    {
        if ( ( condition & IOCondition.HUP ) == IOCondition.HUP )
        {
            FsoFramework.theLogger.error( "HUP on inotify, will no longer get any notifications" );
            return false;
        }

        if ( ( condition & IOCondition.IN ) == IOCondition.IN )
        {
            assert( fd != -1 );
            assert( buffer != null );
            /* ssize_t bytesread = */ Posix.read( fd, buffer, BUFFER_LENGTH );

            Linux.InotifyEvent* pevent = (Linux.InotifyEvent*) buffer;
            handleEvent( *pevent );

            return true;
        }

        critical( "Unsupported IOCondition %u", (int)condition );
        return true;
    }

    protected void handleEvent( Linux.InotifyEvent event )
    {
#if DEBUG
        message( "got inotify event" );
#endif
        unowned INotifyDelegateHolder holder = delegates.lookup( event.wd );
        assert( holder != null );

        holder.func( (Linux.InotifyMaskFlags)event.mask, event.cookie, event.len > 0 ? event.name : null );
    }

    protected uint _add( string path, Linux.InotifyMaskFlags mask, INotifyNotifierFunc cb )
    {
        var wd = Linux.inotify_add_watch( fd, path, mask );
#if DEBUG
        debug( "wd = %d", wd );
#endif
        if ( wd == -1 )
        {
            FsoFramework.theLogger.error( @"inotify_add_watch: $(strerror(errno))" );
            return 0;
        }
        else
        {
            delegates.insert( wd, new INotifyDelegateHolder( cb ) );
#if DEBUG
            debug( "inotifier watch added, total %u", delegates.size() );
#endif
            return wd;
        }
    }

    protected void _remove( uint source )
    {
        unowned INotifyDelegateHolder holder = delegates.lookup( (int)source );
        if ( holder != null )
        {
            Linux.inotify_rm_watch( fd, (int)source );
            delegates.remove( (int)source );
#if DEBUG
            debug( "inotifier watch removed, total %u", delegates.size() );
#endif
        }
    }

    //
    // public API
    //
    public static uint add( string path, Linux.InotifyMaskFlags mask, INotifyNotifierFunc cb )
    {
        if ( INotifier.instance == null )
        {
            INotifier.instance = new INotifier();
        }
        return INotifier.instance._add( path, mask, cb );
    }

    public static void remove( uint source )
    {
        if ( INotifier.instance == null )
        {
            INotifier.instance = new INotifier();
        }
        INotifier.instance._remove( source );
    }
}

