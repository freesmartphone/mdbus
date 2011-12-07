/**
 * Copyright (C) 2011 Klaus 'mrmoku' Kurzmann <mok@fluxnetz.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 **/


GLib.MainLoop mainloop;
FsoFramework.Subsystem subsystem;

int main( string[] args )
{
    subsystem = new FsoFramework.BaseSubsystem( "fsosystem" );
    subsystem.registerPlugins();
    uint count = subsystem.loadPlugins();
    FsoFramework.theLogger.info( "loaded %u plugins".printf( count ) );
    if ( count > 0 )
    {
        mainloop = new GLib.MainLoop(null, false);
        FsoFramework.theLogger.info( "fsosystemd => mainloop" );
        mainloop.run();
        FsoFramework.theLogger.info( "mainloop => fsosystemd" );
    }

    FsoFramework.theLogger.info( "fsosystemd shutdown." );
    return 0;
}

// vim:ts=4:sw=4:expandtab
