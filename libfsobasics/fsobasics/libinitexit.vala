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

namespace FsoFramework
{
    public Logger theLogger;
    public SmartKeyFile theConfig;
    internal GLibLogger glibLogger;

    internal void onSignal( int sig )
    {
        theLogger.error( @"Caught signal $sig" );
        var bt = Utility.createBacktrace();
        foreach( var s in bt )
        {
            s.data[s.length - 1] = '\0';
            theLogger.error( s );
        }
        Posix.signal( sig, Posix.SIG_DFL );
        Posix.exit( sig );
    }
}

static void vala_library_init()
{
    var bin = FsoFramework.Utility.programName();

    FsoFramework.theConfig = FsoFramework.SmartKeyFile.createFromConfig( bin );
    FsoFramework.theLogger = FsoFramework.Logger.createFromKeyFile( FsoFramework.theConfig, "logging", bin );
    var classname = Type.from_instance( FsoFramework.theLogger ).name();

    if ( FsoFramework.theConfig.boolValue( "logging", "log_integrate_glib", true ) )
    {
        FsoFramework.glibLogger = new GLibLogger( FsoFramework.theLogger );
    }

    if ( FsoFramework.theConfig.boolValue( "logging", "log_backtrace", true) )
    {
        var i = 0;
        foreach( var sig in FsoFramework.theConfig.stringListValue( "logging", "log_bt_signals", { "2", "15" } ) )
        {
            Posix.signal( int.parse( sig ), FsoFramework.onSignal );
            i++;
        }

        FsoFramework.theLogger.debug( @"Registered $i backtrace handler" );
    }

    FsoFramework.theLogger.info( @"Binary launched successful ($classname created as theLogger)" );
}

static void vala_library_fini()
{
    FsoFramework.theConfig = null;
    FsoFramework.theLogger = null;
    FsoFramework.glibLogger = null;
}

// only for Vala
internal static void silence_unused_warning()
{
    vala_library_fini();
    vala_library_init();
    silence_unused_warning();
}

// vim:ts=4:sw=4:expandtab
