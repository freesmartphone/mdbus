/*
 * -- Mickey's DBus Utility V2 --
 *
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 */

/**
 * TODO:
 * - Allow specifying the signature for method calls, this becomes necessary
 *   when there is no introspection data available.
 **/

//=========================================================================//
using GLib;

//=========================================================================//
const string DBUS_BUS_NAME  = "org.freedesktop.DBus";
const string DBUS_OBJ_PATH  = "/";
const string DBUS_INTERFACE = "org.freedesktop.DBus";
const string DBUS_INTERFACE_INTROSPECTABLE = "org.freedesktop.DBus.Introspectable";
[DBus (name="org.freedesktop.DBus.Introspectable")]
public interface Introspectable : GLib.Object
{
        public abstract string introspect() throws DBusError, IOError;
}

//=========================================================================//
[DBus (name = "org.freedesktop.DBus", timeout = 120000)]
public interface DBusSync : GLib.Object {
    public abstract string hello() throws DBusError, IOError;
    public abstract uint request_name(string param0, uint param1) throws DBusError, IOError;
    public abstract uint release_name(string param0) throws DBusError, IOError;
    public abstract uint start_service_by_name(string param0, uint param1) throws DBusError, IOError;
    public abstract void update_activation_environment(GLib.HashTable<string, string> param0) throws DBusError, IOError;
    public abstract bool name_has_owner(string param0) throws DBusError, IOError;
    public abstract string[] list_names() throws DBusError, IOError;
    public abstract string[] list_activatable_names() throws DBusError, IOError;
    public abstract void add_match(string param0) throws DBusError, IOError;
    public abstract void remove_match(string param0) throws DBusError, IOError;
    public abstract string get_name_owner(string param0) throws DBusError, IOError;
    public abstract uint get_connection_unix_user(string param0) throws DBusError, IOError;
    public abstract uint get_connection_unix_process_i_d(string param0) throws DBusError, IOError;
    public abstract uint8[] get_adt_audit_session_data(string param0) throws DBusError, IOError;
    public abstract void reload_config() throws DBusError, IOError;
    public abstract string get_id() throws DBusError, IOError;
    public signal void name_owner_changed(string param0, string param1, string param2);
    public signal void name_lost(string param0);
    public signal void name_acquired(string param0);
}
//=========================================================================//
Commands commands;
List<string> completions;
//=========================================================================//

//=========================================================================//
class Commands : Object
{
    DBusConnection bus;
    DBusSync busobj;

    public Commands( GLib.BusType bustype )
    {
        try
        {
            bus = Bus.get_sync( bustype );
            busobj = bus.get_proxy_sync<DBusSync>( DBUS_BUS_NAME, DBUS_OBJ_PATH );
        }
        catch ( Error e )
        {
            stderr.printf( @"Can't hook to DBus %s bus: $(e.message)\n".printf( useSystemBus ? "system" : "session" ) );
            Posix.exit( -1 );
        }
    }

    public bool isValidBusName( string busname )
    {
#if ALWAYS_INTROSPECT
        var allnames = _listBusNames();
        foreach ( var name in allnames )
        {
            if ( busname == name )
            {
                return true;
            }
        }
#else
        var reUnique = /:[0-9]\.[0-9]+/;
        if ( reUnique.match( busname ) )
        {
            return true;
        }
        var reWellKnown = /[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)+/;
        if ( reWellKnown.match( busname ) )
        {
            return true;
        }
#endif
        return false;
    }

    public bool isValidObjectPath( string busname, string path )
    {
#if ALWAYS_INTROSPECT
        var allpaths = new List<string>();
        var o = 
        _listObjects( busname.strip(), "/", ref allpaths );
        foreach ( var p in allpaths )
        {
            if ( path == p )
            {
                return true;
            }
        }
#else
        if ( !isValidBusName( busname ) )
        {
            return false;
        }
        var reObjPath = new GLib.Regex( "^/([a-zA-Z0-9_]+(/[a-zA-Z0-9_]+)*)?$" );
        if ( reObjPath.match( path ) )
        {
            return true;
        }
#endif
        return false;
    }

    private string appendPidToBusName( string name )
    {
        uint pid = 0;

        try
        {
            pid = busobj.get_connection_unix_process_i_d( name );
        }
        catch ( Error e )
        {
#if DEBUG
            debug( "%s", e.message );
#endif
        }
        return "%s (%s)".printf( name, pid > 0 ? pid.to_string() : "unknown" );
    }

    public List<string> _listBusNames( string prefix = "" )
    {
        List<string> sortednames = new List<string>();
        string[] names = new string[0];
        try
        {
            names = busobj.list_names();
        }
        catch (GLib.Error e)
        {
            stdout.printf( @"[ERR]: List busnames: $(e.message)");
            return sortednames;
        }

        if ( showAnonymous )
        {
            foreach ( var name in names )
            {
                if ( name.has_prefix( prefix ) )
                {
                    sortednames.insert_sorted( !interactive && showPIDs ? appendPidToBusName( name ) : name, strcmp );
                }
            }
        }
        else
        {
            foreach ( var name in names )
            {
                if ( !name.has_prefix( ":" ) && name.has_prefix( prefix ) )
                {
                    sortednames.insert_sorted( !interactive && showPIDs ? appendPidToBusName( name ) : name, strcmp );
                }
            }
        }
        return sortednames;
    }

    public void listBusNames()
    {
        foreach ( var name in _listBusNames() )
        {
            stdout.printf( @"$name\n", name );
        }
    }

    public void _listObjects( string busname, string path, ref List<string> result, string prefix = "", bool with_interfaces = false )
    {
        try
        {
            var nodeinfo = getNodeInfo( busname, path );
            if ( path.has_prefix( prefix ) && ( !with_interfaces || ( nodeinfo != null && nodeinfo.interfaces.length > 1 ) ) )
            {
                result.append( path );
            }

            foreach ( var node in nodeinfo.nodes )
            {
                _listObjects( busname, Path.build_filename( path, node.path ), ref result, prefix, with_interfaces );
            }
        }
        catch ( Error e )
        {
            stderr.printf( @"[ERR]: $(e.message)\n" );
            return;
        }
    }

    public void listObjects( string busname, string path = "/" )
    {
        if ( !isValidBusName( busname ) )
        {
            stdout.printf( @"[ERR]: Unknown busname $busname\n" );
            return;
        }
        try
        {
            var names = new List<string>();
            _listObjects( busname, path, ref names );
            foreach ( var name in names )
            {
                stdout.printf( "%s\n", name );
            }

        }
        catch (GLib.Error e)
        {
            stdout.printf( @"[ERR]: Intropecting $(busname) $path: $(e.message)");
        }
    }

    public List<string> _listInterfaces( string busname, string path, string? prefix = null, bool stripPropertiesAndSignals = false )
    {
        var result = new List<string>();

        try
        {
            var nodeinfo = getNodeInfo( busname, path );
            if( nodeinfo == null)
                return result;
            foreach ( var iface in nodeinfo.interfaces )
            {
#if DEBUG
                debug(@"list interface $(iface.name) ");
#endif
                if ( prefix == null )
                {
                    foreach( var s in interfaceDescription( iface, stripPropertiesAndSignals ) )
                        result.append( s );
                }
                else
                {
                    if ( iface.name.has_prefix( prefix ) )
                    {
                        foreach( var s in interfaceDescription( iface, stripPropertiesAndSignals ) )
                            result.append( s );
                    }
                }
            }
        }
        catch ( Error e )
        {
            stderr.printf( "[ERR]: %s\n", e.message );
        }
        return result;
    }

    public void listInterfaces( string busname, string path )
    {
        if ( !isValidBusName( busname ) )
        {
            stdout.printf( @"[ERR]: Unknown busname $busname\n" );
            return;
        }

        if ( !isValidObjectPath( busname, path ) )
        {
            stderr.printf( @"[ERR]: Unknown object path $path for $busname\n" );
            return;
        }
        var nodeinfo = getNodeInfo( busname, path );
        if ( nodeinfo == null )            
        {
            stderr.printf( "[ERR]: No introspection data for object '%s'\n", path );
            return;
        }

        foreach ( var name in _listInterfaces( busname, path ) )
        {
            stdout.printf( "%s\n", name );
        }
    }

    private bool callMethodWithoutIntrospection( string busname, string path, string method )
    {
        var point = method.last_index_of_char( '.' );
        var baseMethod = method.substring( point + 1 , -1);
        var iface = method.substring( 0, point );
        try
        {
            var v = bus.call_sync( busname, path, iface, baseMethod, null, VariantType.ANY, 0, 100000);
            stdout.printf( @"$(v.print(annotateTypes))\n");
        }
        catch (GLib.Error e)
        {
            stdout.printf(@"$(e.message)");
        }
        return true;
    }

    public bool callMethod( string busname, string path, string method, string[] args )
    {
        if ( !isValidBusName( busname ) )
        {
            stdout.printf( @"[ERR]: Unknown busname $busname\n" );
            return false;
        }

        if ( !isValidObjectPath( busname, path ) )
        {
            stderr.printf( @"[ERR]: Unknown object path $path for $busname\n" );
            return false;
        }

        // skip introspection if we don't have any arguments
        if ( args.length == 0 )
        {
            return callMethodWithoutIntrospection( busname, path, method );
        }

        try
        {
            var point = method.last_index_of_char( '.' );
            var baseMethod = method.substring( point + 1 );
            var iface = method.substring( 0, point );
            var nodeinfo = getNodeInfo( busname, path );
            DBusMethodInfo methodinfo = null;

            if ( nodeinfo != null )
            {
                var ifaceinfo = nodeinfo.lookup_interface( iface );
                if( ifaceinfo != null )
                {
                    methodinfo = ifaceinfo.lookup_method( baseMethod );
                }
            }


            if ( methodinfo != null && args.length != methodinfo.in_args.length )
            {
                stderr.printf( "[ERR]: Need %u params for signature '%s', supplied %u\n", methodinfo.in_args.length, buildSignature(methodinfo.in_args), args.length );
                return false;
            }

            var vargs_builder = new VariantBuilder( VariantType.TUPLE );
            for( int i = 0; i < args.length; i++ )
            {
                try
                {
                    unowned VariantType? vt = (methodinfo == null) ? null : new VariantType( methodinfo.in_args[i].signature );
                    var v = Variant.parse( vt, args[i] );
                    vargs_builder.add_value( v );
                }
                catch (GLib.VariantParseError e)
                {
                    stdout.printf( @"[ERR]: $(e.message) while parsing '$(args[i])'\n" );
                    return false;
                }
            }

            var parameters = vargs_builder.end();
            unowned VariantType? full_vt = parameters.get_type();//methodinfo == null ?  : new VariantType( buildSignature( methodinfo.out_args ) );
            var result = bus.call_sync( busname, path, iface, baseMethod, parameters, full_vt, DBusCallFlags.NONE, 100000 );
            stdout.printf( @"$(result.print(annotateTypes))\n" );
        }
        catch ( Error e )
        {
            stderr.printf( "[ERR]: %s\n", e.message );
            return false;
        }
        return false;
    }

    public void signalHandler( GLib.DBusConnection conn, string sender, string path, string iface, string name, Variant params )
    {
        var line = "[SIGNAL] %s.%s  %s  %s\n%s".printf(
          iface,
          name,
          path,
          sender,
          params.print(annotateTypes));
        stdout.printf( @"$line\n" );
    }


    //TODO: filter by method
    public void listenForSignals( string? busname = null, string? objectpath = null, string? iface = null )
    {
        string method = null;
        string realiface = iface;
        if( iface != null)
        {
            var point = iface.last_index_of_char( '.' );
            var tmpiface = iface.substring( 0, point );
            var nodeinfo = getNodeInfo( busname, objectpath );
            if( nodeinfo!= null && nodeinfo.lookup_interface( tmpiface ) != null)
            {
                realiface = tmpiface;
                method = iface.substring( point + 1, -1 );
            }
        }
#if DEBUG
        message( "listening for signal %s %s %s %s", busname, objectpath, realiface, method );
#endif
        bus.signal_subscribe( busname, realiface, method, objectpath, null, DBusSignalFlags.NONE, signalHandler );
        var mainloop = new MainLoop();
        mainloop.run();
    }

    private void performCommandFromShell( string commandline )
    {
        if ( commandline.strip() == "" )
        {
            listBusNames();
            return;
        }

        string[] args;

        try
        {
            GLib.Shell.parse_argv( commandline, out args );
        }
        catch ( GLib.ShellError e )
        {
            stderr.printf( @"[ERR]: Can't parse cmdline: $(e.message)\n" );
            return;
        }

        switch ( args.length )
        {
            case 0:
                stderr.printf( @"Oops!" );
                break;
            case 1:
                listObjects( args[0].strip() );
                break;
            case 2:
                listInterfaces( args[0].strip(), args[1].strip() );
                break;
            default:
                commands.callMethod( args[0].strip(), args[1].strip(), args[2].strip(), args[3:args.length] );
                break;
        }
    }

    /*
    private static unowned string? wordBreakCharacters()
    {
        return " ";
    }
    */

    private static string? completion( string prefix, int state )
    {
        if ( state == 0 )
        {
#if DEBUG
            message( "Readline.line_buffer = '%s'", Readline.line_buffer );
#endif
            var parts = Readline.line_buffer.split( " " );
            if ( parts.length == 0 || parts[0].strip() == "")
            {
                prefix = "";
            }
#if DEBUG
            message( "'%s' length = %d", prefix, parts.length );
#endif
            if ( prefix.has_suffix( " " ) )
            {
                parts.length++;
            }

            switch ( parts.length )
            {
                case 0:
                case 1: /* bus name */
                    completions = commands._listBusNames( prefix.strip() );
                    break;
                case 2: /* object path */
                    completions = new List<string>();
                    commands._listObjects( parts[0].strip(), "/" , ref completions, prefix, true );
                    break;
                case 3: /* interfaces (minus signals or properties) */
                    completions = commands._listInterfaces( parts[0].strip(), parts[1].strip(), prefix, true );
                    break;
                default:
                    return null;
            }
#if DEBUG
            foreach ( var c in completions )
            {
               message( "got completion '%s'", c );
            }
#endif
        }
        return completions.nth_data( state );
    }

    private string buildSignature( DBusArgInfo[] args, bool with_names = false )
    {
        string result = "";
        foreach(var arg in args)
        {
            if( with_names )
                result += @"$(arg.signature):$(arg.name), ";
            else
                result += arg.signature;
        }
        if( with_names )
            result = result.substring( 0, result.length - 2 );
        return result;
    }

    private string[] interfaceDescription( DBusInterfaceInfo iface , bool only_methods )
    {
        string[] result = new string[0];
        foreach( var m in iface.methods )
        {
            if( !only_methods )
                result += methodToString( m, iface.name );
            else
                result += iface.name + "." + m.name;
        }
        if( ! only_methods )
        {
            foreach( var s in iface.signals )
                result += signalToString( s, iface.name );
            foreach( var p in iface.properties )
                result += propertyToString( p, iface.name );
        }
        return result;
    }

    private string propertyToString( DBusPropertyInfo prop, string iface )
    {
        return @"[PROPERTY] $(iface).$(prop.name)($(prop.name):$(prop.signature))";
    }

    private string signalToString( DBusSignalInfo signal, string iface )
    {
        return @"[SIGNAL]    $(iface).$(signal.name)($(buildSignature(signal.args,true)))";
    }

    private string methodToString( DBusMethodInfo method, string iface )
    {
        return @"[METHOD]    $(iface).$(method.name)($(buildSignature(method.in_args,true))) -> ($(buildSignature(method.out_args,true)))";
    }

    public DBusNodeInfo? getNodeInfo( string busname, string path )
    {
        try
        {
            var o = bus.get_proxy_sync<Introspectable>( busname, path );
            return new DBusNodeInfo.for_xml( o.introspect() );
        }
        catch (GLib.Error e)
        {
#if DEBUG
            debug(@"Cannot introspect $busname $path: $(e.message)");
#endif
            return null;
        }
    }

    public void launchShell()
    {
        Readline.initialize();
        Readline.readline_name = "mdbus2";
        Readline.terminal_name = Environment.get_variable( "TERM" );

        Readline.History.read( "%s/.mdbus2.history".printf( Environment.get_variable( "HOME" ) ) );
        Readline.History.max_entries = 512;

        Readline.completion_entry_function = completion;
        //Readline.completion_word_break_hook = wordBreakCharacters;
        // leads to a SIGSEGV (double memory free)
        Readline.parse_and_bind( "tab: complete" );

        Readline.completer_word_break_characters = " ";
        Readline.basic_quote_characters = " ";
        Readline.completer_word_break_characters = " ";
        Readline.filename_quote_characters = " ";

        var done = false;

        while ( !done )
        {
            var line = Readline.readline( "MDBUS2> " );
            if ( line == null ) // ctrl-d
            {
                done = true;
            }
            else
            {
                if ( line != "" )
                {
                    Readline.History.add( line );
                }
                performCommandFromShell( line );
            }
        }
        stderr.printf( "Good bye!\n" );
        Readline.History.write( "%s/.mdbus2.history".printf( Environment.get_variable( "HOME" ) ) );
    }
}

//=========================================================================//
bool showAnonymous;
bool listenerMode;
bool showPIDs;
bool useSystemBus;
bool interactive;
bool annotateTypes;

const OptionEntry[] options =
{
    { "show-anonymous", 'a', 0, OptionArg.NONE, ref showAnonymous, "Show anonymous names", null },
    { "show-pids", 'p', 0, OptionArg.NONE, ref showPIDs, "Show unix process IDs", null },
    { "listen", 'l', 0, OptionArg.NONE, ref listenerMode, "Listen for signals", null },
    { "system", 's', 0, OptionArg.NONE, ref useSystemBus, "Use System Bus", null },
    { "interactive", 'i', 0, OptionArg.NONE, ref interactive, "Enter interactive shell", null },
    { "annotate-types", 't', 0, OptionArg.NONE, ref annotateTypes, "Annotate DBus type", null },
    { null }
};

//=========================================================================//
int main( string[] args )
{
    try
    {
        var opt_context = new OptionContext( "[ busname [ objectpath [ method [ params... ] ] ] ]" );
        opt_context.set_summary( "Mickey's DBus Introspection and Interaction Utility V2" );
        opt_context.set_description( """This utility helps you to explore and interact with DBus
services on your system bus and session bus. Called without
any parameters, it will show the available services on the
selected bus. Given a service name, it will show the avail-
able objects exported by the service. Given a service name
and an object path, it will show the exposed methods, sig-
nals, and properties of that object.

mdbus2 -i drops you into a shell mode, where you can inter-
actively explore services and call methods using readline
command line completion and history.

mdbus2 -l drops you into the listener mode, where everything
that happens on the bus is monitored.

NOTE: Mickey's DBus Utility requires well-behaved services,
i.e. those which implement the DBus introspection protocol.

mdbus2: DBus has never been that much fun!""" );
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

    commands = new Commands( useSystemBus ? BusType.SYSTEM : BusType.SESSION );

    switch ( args.length )
    {
        case 1:
            if ( interactive )
            {
                commands.launchShell();
                return 0;
            }

            if (!listenerMode)
                commands.listBusNames();
            else
                commands.listenForSignals();
            break;

        case 2:
            if ( !listenerMode )
                commands.listObjects( args[1].strip() );
            else
                commands.listenForSignals( args[1].strip() );
            break;

        case 3:
            if ( !listenerMode )
                commands.listInterfaces( args[1].strip(), args[2].strip() );
            else
                commands.listenForSignals( args[1].strip(), args[2].strip() );
            break;

        default:
            assert( args.length > 3 );

            if ( listenerMode )
            {
                commands.listenForSignals( args[1], args[2], args[3] );
                return 0;
            }

            string[] restargs = {};
            for ( int i = 4; i < args.length; ++i )
            {
                restargs += args[i];
            }
            var ok = commands.callMethod( args[1].strip(), args[2].strip(), args[3].strip(), restargs );
            return ok ? 0 : -1;
    }

    return 0;
}

// vim:ts=4:sw=4:expandtab
