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
 **/

namespace FsoFramework { namespace Threading {

public delegate void VoidFuncWithVoidStarParam( void* param );

internal class DummyThread
{
    private VoidFuncWithVoidStarParam func;
    private void* param;
    public DummyThread* pself;

    public DummyThread( VoidFuncWithVoidStarParam func, void* param )
    {
        this.func = func;
        this.param = param;
#if DEBUG
        debug( "Thread %p %p construct", (void*)this.func, this.param );
#endif
    }

    public void launch( DummyThread* pself )
    {
        assert( pself != null );
        this.pself = pself;
        try
        {
            Thread.create<void*>( main, false );
        }
        catch ( GLib.ThreadError e )
        {
            error( @"Can't spawn thread: $(e.message)" );
        }
    }

    public void* main()
    {
        assert( this != null );
        assert( func != null );
        func( param );
        delete pself;
        return null;
    }

    ~DummyThread()
    {
#if DEBUG
        debug( "Thread %p %p destruct", (void*)this.func, this.param );
#endif
    }
}

public bool isMainThread()
{
    return ( Linux.gettid() == Posix.getpid() );
}

public void callDelegateOnMainThread( VoidFuncWithVoidStarParam func,
                                      bool waitForCompletion = false,
                                      void* param = 0x0 )
{
    var mutex = new GLib.Mutex();
    var cond = new GLib.Cond();

    if ( isMainThread() )
    {
        if ( waitForCompletion )
        {
            func( param );
        }
        else
        {
            Idle.add( () => { func(param); return false; } );
        }
    }
    else
    {
        if ( waitForCompletion )
        {
            Idle.add( () => { func( param ); cond.broadcast(); return false; } );
#if DEBUG
            debug( "sleeping on conditional now..." );
#endif
            cond.wait( mutex );
#if DEBUG
            debug( "woke up from sleeping" );
#endif
        }
        else
        {
            Idle.add( () => { func(param); return false; } );
        }
    }
}

public void callDelegateOnNewThread( VoidFuncWithVoidStarParam func,
                                      void* param )
{
    DummyThread* thread = new DummyThread( func, param );
    thread->launch( thread );
}

} }
