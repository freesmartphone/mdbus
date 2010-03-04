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

public class MsmCommandBundle
{
    public Msmcomm.Message command;
    public uint retry;
    public Msmcomm.Message response;
    public SourceFunc callback;
}

public class MsmCommandQueue : FsoFramework.CommandQueue, GLib.Object
{
    // don't access this unless absolutely necessary
    public FsoFramework.Transport transport;

    protected Gee.LinkedList<MsmCommandBundle> q;
    protected MsmCommandBundle current;
    protected uint timeout;

    protected char* buffer;

    protected void _writeRequestToTransport( string request )
    {
        assert( current != null );

        // ... write

        /*
        if ( seconds > 0 )
        {
            timeout = Timeout.add_seconds( seconds, _onTimeout );
        }
        */
    }

    protected void _onReadFromTransport( FsoFramework.Transport t )
    {
        if ( timeout > 0 )
        {
            Source.remove( timeout );
        }

        // tell msmcomm we have something to read

        /*
        var bytesread = transport.read( buffer, COMMAND_QUEUE_BUFFER_SIZE );
        buffer[bytesread] = 0;
        onReadFromTransport( (string)buffer );
        */
    }

    protected void _onHupFromTransport( FsoFramework.Transport t )
    {
        // HUP
    }

    protected bool _onTimeout()
    {
        // TIMEOUT
        return false;
    }

    protected bool _haveCommand()
    {
        return ( current != null );
    }

    //
    // subclassing API
    //

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
        // send command via msm transport
    }

    //
    // public API
    //

    public MsmCommandQueue( FsoFramework.Transport transport )
    {
        q = new Gee.LinkedList<MsmCommandBundle>();
        this.transport = transport;
        transport.setDelegates( _onReadFromTransport, _onHupFromTransport );
    }

    ~MsmCommandQueue()
    {
    }

    public void registerUnsolicitedHandler( FsoFramework.CommandQueue.UnsolicitedHandler urchandler )
    {
    }

    public async string[] enqueueAsyncYielding( FsoFramework.CommandQueueCommand command, string request, uint retry = DEFAULT_RETRY )
    {
        return {};
    }

    public async Msmcomm.Message processMsmCommand( Msmcomm.Message* command )
    {
        assert_not_reached();
    }

    public bool open()
    {
        // open transport
        assert( !transport.isOpen() );
        if ( !transport.open() )
            return false;
        else
            return true;
        //TODO: more initialization necessary?
    }

    public void freeze( bool drain = false )
    {
        assert_not_reached();
    }

    public void thaw()
    {
        assert_not_reached();
    }

    public void close()
    {
        transport.close();
    }
}
