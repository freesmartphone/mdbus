/**
 * -- Mickey's DBus Utility V2 --
 *
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

//=========================================================================//
using GLib;

//=========================================================================//
const string DBUS_BUS_NAME  = "org.freedesktop.DBus";
const string DBUS_OBJ_PATH  = "/";
const string DBUS_INTERFACE = "org.freedesktop.DBus";
const string DBUS_INTERFACE_INTROSPECTABLE = "org.freedesktop.DBus.Introspectable";

//=========================================================================//
MainLoop mainloop;

//===========================================================================
public class Argument : Object
{
    public Argument( string name, string typ )
    {
        this.name = name;
        this.typ = typ;
    }
    public string name;
    public string typ;
}

//===========================================================================
public class Method : Object
{
    public Method( string name, bool signal = false )
    {
        this.name = name;
        this.signal = signal;
    }

    public string to_string()
    {
        string line = signal ? "[SIGNAL]    %s(%s)" : "[METHOD]    %s(%s) -> (%s)";
        string inargs = "";
        string outargs = "";

        foreach ( var arg in inArgs )
        {
            inargs += " %s:%s,".printf( arg.typ, arg.name );
        }
        if ( inArgs.length() > 0 )
            ( (char[]) inargs )[inargs.length-1] = ' ';

        if ( outArgs.length() > 0 )
        {
            foreach ( var arg in outArgs )
            {
                outargs += " %s:%s,".printf( arg.typ, arg.name );
            }
            ( (char[]) outargs )[outargs.length-1] = ' ';
        }

        line = line.printf( name, inargs, outargs );
        return line;
    }

    public string name;
    public bool signal;
    public List<Argument> inArgs;
    public List<Argument> outArgs;
}

//===========================================================================
public class Introspection : Object
{
    private string[] _xmldata;

    public List<string> nodes;
    public List<string> interfaces;
    public List<Method> methods;

    private string iface;
    private Method method;

    public Introspection( string xmldata )
    {
        message( "introspection object created" );

        MarkupParser parser = { startElement, null, null, null, null };
        var mpc = new MarkupParseContext( parser, MarkupParseFlags.TREAT_CDATA_AS_TEXT, this, null );

        foreach ( var line in xmldata.split( "\n" ) )
        {
            if ( line[1] != '!' || line[0] != '"' )
            {
                //message( "dealing with line '%s'", line );
                mpc.parse( line, line.length );
            }
        }
    }

    public void startElement( MarkupParseContext context,
                              string element_name,
                              string[] attribute_names,
                              string[] attribute_values ) throws MarkupError
    {
        //message( "start element '%s'", element_name );

        foreach ( var attribute in attribute_names )
        {
            //message( "attribute name '%s'", attribute );
        }
        foreach ( var value in attribute_values )
        {
            //message( "attribute value '%s'", value );
        }

        switch ( element_name )
        {
            case "node":
                if ( attribute_names != null &&
                     attribute_names[0] == "name" &&
                     attribute_values != null &&
                     attribute_values[0][0] != '/' &&
                     attribute_values[0] != "" )
                {
                    nodes.append( attribute_values[0] );
                }
                break;
            case "interface":
                iface = attribute_values[0];
                interfaces.append( iface );
                break;
            case "method":
                method = new Method( "%s.%s".printf( iface, attribute_values[0] ), false );
                methods.append( method );
                break;
            case "signal":
                method = new Method( "%s.%s".printf( iface, attribute_values[0] ), true );
                methods.append( method );
                break;
            case "arg":
                assert( method != null );

                string name = "none";
                string direction = "out";
                string typ = "?";

                for ( int i = 0; i < attribute_names.length; ++i )
                {
                    switch ( attribute_names[i] )
                    {
                        case "name":
                            name = attribute_values[i];
                            break;
                        case "direction":
                            direction = attribute_values[i];
                            break;
                        case "type":
                            typ = attribute_values[i];
                            break;
                    }
                }

                var arg = new Argument( name, typ );
                if ( direction == "out" )
                    method.outArgs.append( arg );
                else
                    method.inArgs.append( arg );
                break;

            default:
                assert_not_reached();
        }
    }
}

//=========================================================================//
class Commands : Object
{
    DBus.Connection bus;
    dynamic DBus.Object busobj;

    public Commands( DBus.BusType bustype )
    {
        try
        {
            bus = DBus.Bus.get( bustype );
            busobj = bus.get_object( DBUS_BUS_NAME, DBUS_OBJ_PATH, DBUS_INTERFACE );
        }
        catch ( DBus.Error e )
        {
            critical( "dbus error: %s", e.message );
        }
    }

    private string appendPidToBusName( string name )
    {
        try
        {
            return "%s (%s)".printf( name, busobj.GetConnectionUnixProcessID( "%s".printf( name ) ) );
        }
        catch ( DBus.Error e )
        {
            debug( "%s", e.message );
            return "%s (unknown)".printf( name );
        }
    }

    public void listBusNames()
    {
        string[] names = busobj.ListNames();
        List<string> sortednames = new List<string>();

        if ( showAnonymous )
        {
            foreach ( var name in names )
            {
                sortednames.insert_sorted( showPIDs ? appendPidToBusName( name ) : name, strcmp );
            }
        }
        else
        {
            foreach ( var name in names )
            {
                if ( !name.has_prefix( ":" ) )
                {
                    sortednames.insert_sorted( showPIDs ? appendPidToBusName( name ) : name, strcmp );
                }
            }
        }

        foreach ( var name in sortednames )
        {
            stdout.printf( "%s\n", name );
        }
    }

    public void listObjects( string busname, string path = "/" )
    {
        dynamic DBus.Object o = bus.get_object( busname, path, DBUS_INTERFACE_INTROSPECTABLE );
        stdout.printf( "%s\n", path );

        try
        {
            var idata = new Introspection( o.Introspect() );
            foreach ( var node in idata.nodes )
            {
                message ( "node = '%s'", node );

                var nextnode = ( path == "/" ) ? "/%s".printf( node ) : "%s/%s".printf( path, node );
                message( "nextnode = '%s'", nextnode );
                listObjects( busname, nextnode );
            }
        }
        catch ( DBus.Error e )
        {
            stderr.printf( "Error: %s\n", e.message );
            return;
        }
    }

    public void listInterfaces( string busname, string path )
    {
        dynamic DBus.Object o = bus.get_object( busname, path, DBUS_INTERFACE_INTROSPECTABLE );

        try
        {
            var idata = new Introspection( o.Introspect() );
            foreach ( var method in idata.methods )
                stdout.printf( "%s\n", method.to_string() );
        }
        catch ( DBus.Error e )
        {
            stderr.printf( "Error: %s\n", e.message );
            return;
        }
    }

}

//=========================================================================//
bool showAnonymous;
bool listenerMode;
bool showPIDs;
bool useSystemBus;

const OptionEntry[] options =
{
    { "show-anonymous", 'a', 0, OptionArg.NONE, ref showAnonymous, "Show anonymous names", null },
    { "show-pids", 'p', 0, OptionArg.NONE, ref showPIDs, "Show unix process IDs", null },
    { "listen", 'l', 0, OptionArg.NONE, ref listenerMode, "Listen for signals", null },
    { "system", 's', 0, OptionArg.NONE, ref useSystemBus, "Use System Bus", null },
        /*
    { "listen", 0, 0, OptionArg.STRING, ref cc_command, "Use COMMAND as C compiler command", "COMMAND" },
    { "", 0, 0, OptionArg.STRING_ARRAY, ref sources, null, "FILE..." },
        */
    { null }
};

//=========================================================================//
int main( string[] args )
{
    try
    {
        var opt_context = new OptionContext( "- Mickey's DBus Utility V2" );
        opt_context.set_help_enabled( true );
        opt_context.add_main_entries( options, null );
        opt_context.parse( ref args );
    }
    catch ( OptionError e )
    {
        stdout.printf( "%s\n", e.message );
        stdout.printf( "Run '%s --help' to see a full list of available command line options.\n", args[0] );
        return 1;
    }

    var commands = new Commands( useSystemBus ? DBus.BusType.SYSTEM : DBus.BusType.SESSION );

    switch ( args.length )
    {
        case 1:
            commands.listBusNames();
            break;

        case 2:
            commands.listObjects( args[1] );
            break;

        case 3:
            commands.listInterfaces( args[1], args[2] );
            break;
    }

    /*
    if (version)
    {
        stdout.printf ("Vala %s\n", Config.PACKAGE_VERSION);
        return 0;
    }

    if (sources == null) {
        stderr.printf ("No source file specified.\n");
        return 1;
    }
    */

    return 0;
}

