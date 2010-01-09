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

using GLib;
using FsoFramework;

MainLoop loop;
int counter;

public static void* thread_func_async()
{
    //debug( "thread running..." );
    assert( ! Threading.isMainThread() );
    Thread.usleep( 10 );
    Threading.callDelegateOnMainThread( someDelegate );
    return null;
}

public static void* thread_func_sync()
{
    //debug( "thread running..." );
    assert( ! Threading.isMainThread() );
    Thread.usleep( 10 );
    Threading.callDelegateOnMainThread( someDelegate, true );
    return null;
}

public void someDelegate( void* data )
{
    //debug( "delegate ENTER launching quit in 2 seconds" );
    Timeout.add_seconds( 2, () => { loop.quit(); return false; } );
    Thread.usleep( 500 );
    //debug( "delegate LEAVE" );
}

public void anotherDelegate( void* data )
{
    //debug( "delegate ENTER %p", data );
    Thread.usleep( Random.next_int() % ( 1000 * 1000 ) );
    //debug( "delegate LEAVE %p", data );
    if ( --counter == 0 )
    {
        loop.quit();
    }
}

//===========================================================================
void test_threading_call_delegate_on_main_thread_async()
//===========================================================================
{  
    loop = new MainLoop();
    Thread.create( thread_func_async, false);
    loop.run();
}

//===========================================================================
void test_threading_call_delegate_on_main_thread_sync()
//===========================================================================
{
    loop = new MainLoop();
    Thread.create( thread_func_sync, false);
    loop.run();
}

//===========================================================================
void test_threading_call_delegate_on_new_thread()
//===========================================================================
{
    loop = new MainLoop();
    for ( int i = 1; i <= 50; ++i )
    {
        //debug( "creating thread %d", i );
        counter++;
        Threading.callDelegateOnNewThread( anotherDelegate, (void*)i );
        //debug( "sleeping..." );
        Thread.usleep( 500 );
    }
    loop.run();
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Threading/callDelegateOnMainThread/ASync", test_threading_call_delegate_on_main_thread_async );
    Test.add_func( "/Threading/callDelegateOnMainThread/Sync", test_threading_call_delegate_on_main_thread_sync );
    Test.add_func( "/Threading/callDelegateOnNewThread", test_threading_call_delegate_on_new_thread );

    Test.run();
}
