/**
 * Copyright (C) 2012 Simon Busch <morphis@gravedo.de>
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

public class TestEmitter : GLib.Object
{
    public void emit0()
    {
    }

    public void emit1()
    {
        s0();
    }

    public void emit2()
    {
        s0();
        s1();
    }

    public signal void s0();
    public signal void s1();
}

void test_multi_signal_waiter_no_signal()
{
    var emitter = new TestEmitter();
    var waiter = new FsoFramework.Test.MultiSignalWaiter();
    waiter.add_signal( emitter, "s0" );
    waiter.add_signal( emitter, "s1" );
    assert( waiter.run( () => { emitter.emit0(); } ) == false );
}

void test_multi_signal_waiter_one_signal()
{
    var emitter = new TestEmitter();
    var waiter = new FsoFramework.Test.MultiSignalWaiter();
    waiter.add_signal( emitter, "s0" );
    assert( waiter.run( () => { emitter.emit0(); } ) == false );
    assert( waiter.run( () => { emitter.emit1(); } ) == true );
    assert( waiter.run( () => { emitter.emit2(); } ) == true );
}

void test_multi_signal_waiter_many_signals()
{
    var emitter = new TestEmitter();
    var waiter = new FsoFramework.Test.MultiSignalWaiter();
    waiter.add_signal( emitter, "s0" );
    waiter.add_signal( emitter, "s1" );
    assert( waiter.run( () => { emitter.emit1(); } ) == false );
    assert( waiter.run( () => { emitter.emit2(); } ) == true );
    assert( waiter.run( () => { emitter.emit0(); } ) == false );
}

void main( string[] args )
{
    Test.init( ref args );

    Test.add_func( "/FsoFramework/Test/MultiSignalWaiter/NoSignal", test_multi_signal_waiter_no_signal );
    Test.add_func( "/FsoFramework/Test/MultiSignalWaiter/TwoSignals", test_multi_signal_waiter_one_signal );
    Test.add_func( "/FsoFramework/Test/MultiSignalWaiter/ManySignals", test_multi_signal_waiter_many_signals );

    Test.run();
}

// vim:ts=4:sw=4:expandtab
