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

using GLib;
using FsoDevice;

//===========================================================================
void test_controls()
//===========================================================================
{
    var sd = SoundDevice.create( "hw:0" );
    var controls = sd.allMixerControls();
    debug( "# of controls = %d", controls.length );
    foreach ( var control in controls )
    {
        debug( "Control: %s", control.to_string() );
    }

    sd.setAllMixerControls( controls );
}

//===========================================================================
void test_mixer()
//===========================================================================
{
    var sd = SoundDevice.create( "hw:0" );
    var mainvolume = sd.volumeForIndex( 0 );
    debug( @"mainvolume now $mainvolume" );
    sd.setVolumeForIndex( 0, 42 );
    mainvolume = sd.volumeForIndex( 0 );
    debug( @"mainvolume now $mainvolume" );
    //assert( sd.volumeForIndex( 0 ) == 42 );
}

//===========================================================================
void main( string[] args )
//===========================================================================
{
    Test.init( ref args );

    // Test.add_func( "/SoundSystem/Controls", test_controls );
    // Test.add_func( "/SoundSystem/Mixer", test_mixer );

    Test.run();
}

// vim:ts=4:sw=4:expandtab
