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


namespace FsoFramework { namespace Threading {

public delegate void VoidFuncWithVoidStarParam( void* param );

internal bool initialized;

public void init()
{
    if ( initialized )
    {
        return;
    }
    initialized = true;
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

    init();

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
        assert( GLib.Thread.supported() );
        if ( waitForCompletion )
        {
            Idle.add( () => { func( param ); cond.broadcast(); return false; } );
            debug( "sleeping on conditional now..." );
            //mutex.lock();
            cond.wait( mutex );
            debug( "woke up from sleeping" );
        }
        else
        {
            Idle.add( () => { func(param); return false; } );
        }
    }
}

} }
