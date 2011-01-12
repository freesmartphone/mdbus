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
 */

namespace FsoFramework
{
    public Logger theLogger;
    public SmartKeyFile theConfig;
}

internal GLibLogger glib_logger;

static void vala_library_init()
{
    var bin = FsoFramework.Utility.programName();
    FsoFramework.theConfig = FsoFramework.SmartKeyFile.createFromConfig( bin );
    FsoFramework.theLogger = FsoFramework.Logger.createFromKeyFile( FsoFramework.theConfig, "logging", bin );
    var classname = Type.from_instance( FsoFramework.theLogger ).name();
    FsoFramework.theLogger.info( @"Binary launched successful ($classname created as theLogger)" );

    glib_logger = new GLibLogger( FsoFramework.theLogger );
    //register to glib domain
    Log.set_handler( "GLib", LogLevelFlags.LEVEL_MASK | LogLevelFlags.FLAG_RECURSION | LogLevelFlags.FLAG_FATAL, glib_logger.log );
    //register to all unknown as fallback
    Log.set_default_handler( glib_logger.log );
}

static void vala_library_fini()
{
    FsoFramework.theConfig = null;
    FsoFramework.theLogger = null;
    glib_logger = null;
}

// only for Vala
internal static void silence_unused_warning()
{
    vala_library_fini();
    vala_library_init();
    silence_unused_warning();
}
