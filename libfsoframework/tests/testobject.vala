/**
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

using GLib;
using FsoFramework;

public class Foo : AbstractObject
{
    public override string repr()
    {
        return "<Foo>";
    }
}

public class FooBar : AbstractObject
{
    public override string repr()
    {
        return "<FooBar>";
    }
}

//===========================================================================
void test_object_creation()
//===========================================================================
{
    var foo = new Foo();
    assert( foo.classname == "Foo" );
    assert( foo.repr() == "<Foo>" );

    var foobar = new FooBar();
    assert( foobar.classname == "FooBar" );
    assert( foobar.repr() == "<FooBar>" );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Object/Creation", test_object_creation );

    Test.run();
}
