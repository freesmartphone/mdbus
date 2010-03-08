/**
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

/**
 * @interface FsoFramework.CommandQueue
 **/
public abstract interface FsoFramework.CommandQueue : GLib.Object
{
    public delegate void UnsolicitedHandler( string prefix, string response, string? pdu = null );

    /**
     * The underlying transport
     **/
    public abstract Transport transport { get; set; }

    public const uint DEFAULT_RETRY = 3;

    /**
     * Open the command queue
     **/
    public abstract async bool open();
    /**
     * Close the command queue
     **/
    public abstract async void close();
    /**
     * Register @a UnsolicitedHandler delegate that will be called for incoming URCs
     **/
    public abstract void registerUnsolicitedHandler( UnsolicitedHandler urchandler );
    /**
     * Halt the Queue operation. Stop accepting any more commands. If drain is true, send
     * all commands that are in the Queue at this point.
     **/
    public abstract async void freeze( bool drain = false );
    /**
     * Resume the Queue operation.
     **/
    public abstract async void thaw();
}

/**
 * @class FsoFramework.AbstractCommandHandler
 **/
public abstract class FsoFramework.AbstractCommandHandler
{
    public uint timeout;
    public int retry;
    public SourceFunc callback;

    public abstract void writeToTransport( FsoFramework.Transport t );
    public abstract string to_string();
}

/**
 * @class FsoFramework.AbstractCommandQueue
 **/
public abstract class FsoFramework.AbstractCommandQueue : FsoFramework.CommandQueue, GLib.Object
{
    public Transport transport { get; set; }
    private Gee.LinkedList<AbstractCommandHandler> q;

    protected FsoFramework.CommandQueue.UnsolicitedHandler urchandler;

    protected AbstractCommandHandler current;

    protected abstract void onReadFromTransport( FsoFramework.Transport t );

    protected bool checkRestartingQ()
    {
        if ( current == null && q.size > 0 )
        {
            writeNextCommand();
            return true;
        }
        else
        {
            return false;
        }
    }

    protected void writeNextCommand()
    {
        current = q.poll_head();
        current.writeToTransport( transport );
        assert( transport.logger.debug( @"Wrote '$current'. Waiting for answer..." ) );
    }

    protected void onHupFromTransport()
    {
        transport.logger.warning( "HUP from transport. closing." );
        transport.close();
        //FIXME: Try to open again or leave that to the higher layers?
    }

    protected void enqueueCommand( AbstractCommandHandler command )
    {
        q.offer_tail( command );
        Idle.add( checkRestartingQ );
    }

    //
    // public API
    //
    public AbstractCommandQueue( Transport transport )
    {
        q = new Gee.LinkedList<AbstractCommandHandler>();
        this.transport = transport;
        transport.setDelegates( onReadFromTransport, onHupFromTransport );
    }

    public void registerUnsolicitedHandler( FsoFramework.CommandQueue.UnsolicitedHandler urchandler )
    {
        assert( this.urchandler == null );
        this.urchandler = urchandler;
    }

    public virtual async bool open()
    {
        // open transport
        assert( !transport.isOpen() );

        var opened = yield transport.openAsync();

        return opened;
    }

    public virtual async void freeze( bool drain = false )
    {
        assert_not_reached();
    }

    public virtual async void thaw()
    {
        assert_not_reached();
    }

    public virtual async void close()
    {
        transport.close();
    }
}
