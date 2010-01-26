/**
 * FSO Resource Abstraction
 *
 * (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

using GLib;
using Gee;

namespace Usage {
/**
 * @class Command
 *
 * Performs the serialization of commands
 **/
public class Command
{
    private GLib.SourceFunc callback;
    protected unowned Resource r;

    public Command( Resource r )
    {
        assert( r != null );
        this.r = r;
        debug( "Created command %p", this );
    }

    public void dequeue()
    {
        assert( r != null );
        assert( r.q.poll_head() == this );

        if ( !r.q.is_empty )
        {
            r.q.peek_head().callback();
        }
    }

    public async void enqueue()
    {
        assert( r != null );
        var wasempty = r.q.is_empty;

        this.callback = enqueue.callback;
        r.q.offer_tail( this );

        if ( wasempty )
        {
            return;
        }
        else
        {
            yield;
        }
    }

    ~Command()
    {
        debug( "Destroying %p", this );
        dequeue();
    }
}

public class RequestResource : Command
{
    public RequestResource( Resource r )
    {
        base( r );
    }

    public async void run( DBus.BusName user ) throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBus.Error
    {
        yield enqueue();
        yield r.addUser( user );
    }
}

public class ReleaseResource : Command
{
    public ReleaseResource( Resource r )
    {
        base( r );
    }

    public async void run( DBus.BusName user ) throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBus.Error
    {
        yield enqueue();
        yield r.delUser( user );
    }
}

public class SetResourcePolicy : Command
{
    public SetResourcePolicy( Resource r )
    {
        base( r );
    }

    public async void run( string policy ) throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBus.Error
    {
    }
}

public class GetResourcePolicy : Command
{
    public GetResourcePolicy( Resource r )
    {
        base( r );
    }

    public async void run() throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBus.Error
    {
    }
}

public class Suspend : Command
{
    public async void run() throws FreeSmartphone.UsageError, FreeSmartphone.Error, DBus.Error
    {
        instance.system_action( FreeSmartphone.UsageSystemAction.SUSPEND ); // DBUS SIGNAL
        yield instance.suspendAllResources();
        // we need to suspend async, otherwise the dbus call would timeout
        Idle.add( instance.onIdleForSuspend );
    }
}

} /* namespace Usage */
