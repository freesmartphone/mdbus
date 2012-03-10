/*
 * Copyright (C) 2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

//===========================================================================
void test_modules_insert()
{
    FsoFramework.Kernel.insertModule( "/lib/modules/2.6.35-23-generic/kernel/drivers/block/floppy.ko" );
}

//===========================================================================
void test_modules_remove()
{
    FsoFramework.Kernel.removeModule( "/lib/modules/2.6.35-23-generic/kernel/drivers/block/floppy.ko" );
}

//===========================================================================
void test_modules_probe()
{
    FsoFramework.Kernel.probeModule( "mtdblock" );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    Test.add_func( "/Modules/Insert", test_modules_insert );
    Test.add_func( "/Modules/Remove", test_modules_remove );
    Test.add_func( "/Modules/Probe", test_modules_probe );

    Test.run();
}

// vim:ts=4:sw=4:expandtab
