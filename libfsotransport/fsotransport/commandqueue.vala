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
    public uint retry;
    public SourceFunc callback;
    // expose wether this command expects a response from the remote side
    public bool sync = false;

    public abstract void writeToTransport( FsoFramework.Transport t );
    public abstract string to_string();
}

/**
 * @class FsoFramework.AbstractCommandQueue
 **/
public abstract class FsoFramework.AbstractCommandQueue : FsoFramework.CommandQueue, GLib.Object
{
    /**
     * @property transport - The underlying transport
     **/
    public Transport transport { get; set; }
    /**
     * Sent, when an error has occured
     **/
    public signal void hangup();

    //
    // private API
    //
    private Gee.LinkedList<AbstractCommandHandler> q;
    private uint timeoutWatch;

    //
    // protected API
    //
    protected FsoFramework.CommandQueue.UnsolicitedHandler urchandler;
    protected AbstractCommandHandler current;
    protected abstract void onReadFromTransport( FsoFramework.Transport t );

    protected bool checkRestartingQ()
    {
        if ( current == null && q.size > 0 )
            writeNextCommand();
        return (q.size > 0);
    }

    protected void writeNextCommand()
    {
        assert( transport.logger.debug( @"Attemping to write next command to transport; we have $(q.size) commands pending!" ) );
        current = q.poll_head();
        current.writeToTransport( transport );

        if ( !current.sync )
        {
            assert( transport.logger.debug( @"Wrote '$current'. Waiting ($(current.timeout)s) for answer..." ) );
            if ( current.timeout > 0 )
            {
                timeoutWatch = GLib.Timeout.add_seconds( current.timeout, onTimeout );
            }
        }
        else
        {
            current = null;
        }
    }

    protected void resetTimeout()
    {
        if ( timeoutWatch > 0 )
        {
            GLib.Source.remove( timeoutWatch );
        }
    }

    protected void onHupFromTransport()
    {
        transport.logger.warning( "HUP from transport; signalling to upper layer" );
        this.hangup(); // emit HUP signal
    }

    protected bool onTimeout()
    {
        assert( transport.logger.warning( @"Timeout while waiting for an answer to '$current'" ) );
        if ( current.retry > 0 )
        {
            current.retry--;
            assert( transport.logger.debug( @"Retrying '$current', retry counter = $(current.retry)" ) );
            current.writeToTransport( transport );
            return true; // call me again
        }
        else
        {
            onResponseTimeout( current ); // derived class is responsible for relaunching the command queue
        }
        return false; // don't call me again
    }

    protected virtual void onResponseTimeout( AbstractCommandHandler ach )
    {
    }

    protected void enqueueCommand( AbstractCommandHandler command )
    {
        q.offer_tail( command );
        Idle.add( checkRestartingQ );
    }

    protected void reset()
    {
        transport.logger.info( "Reset commandqueue ..." );
        current = null;
        q.clear();
    }

    protected bool is_busy()
    {
        return q.size > 0;
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

// vim:ts=4:sw=4:expandtab
