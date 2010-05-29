/*
 * -- Mickey's DBus Utility V2 --
 *
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

//=========================================================================//
MainLoop mainloop;
Commands commands;
List<string> completions;
//=========================================================================//

public string formatSimpleContainerIter( DBus.RawMessageIter subiter, string start, string trenner, string stop, int depth = 0 )
{
#if DEBUG
    debug( @"formatSimpleContainerIter: depth = $depth, subiter.has_next() = $(subiter.has_next())" );
#endif

    // check for empty container
    if ( depth > 1 && !subiter.has_next() )
    {
        var result = formatResult( subiter, depth+1 );
        return @"$start $result $stop";
        //return @"$start $stop";
    }

    var result = "";
    result += start + " ";
    var next = true;
    while ( next )
    {
        result += formatResult( subiter, depth+1 );
        if ( subiter.has_next() )
        {
            result += ", ";
        }
        next = subiter.next();
    }
    result += " " + stop;
    return result;
}

public string formatMessage( DBus.RawMessage msg )
{
#if DEBUG
    debug( @"message has signature: $(msg.get_signature())" );
#endif

    DBus.RawMessageIter iter = DBus.RawMessageIter();
    if ( msg.iter_init( iter ) )
    {
        return formatSimpleContainerIter( iter, "(", ",", ")" );
    }
    else
    {
        return "()";
    }
}

public string formatResult( DBus.RawMessageIter iter, int depth = 0 )
{
    var signature = iter.get_signature();
#if DEBUG
    debug( @"signature for this iter = $signature" );
#endif
    /*
     * Dictionary container
     */
    if ( signature[0] == 'a' && signature[1] == '{' )
    {
        DBus.RawMessageIter subiter = DBus.RawMessageIter();
        iter.recurse( subiter );
        return formatSimpleContainerIter( subiter, "{", ",", "}", depth+1 );
    }

    /*
     * Array container
     */
    if ( signature[0] == 'a' )
    {
        DBus.RawMessageIter subiter = DBus.RawMessageIter();
        iter.recurse( subiter );
        return formatSimpleContainerIter( subiter, "[", ",", "]", depth+1 );
    }

    /*
     * Structure
     */
    if ( signature[0] == '(' && signature[signature.length-1] == ')' )
    {
        DBus.RawMessageIter subiter = DBus.RawMessageIter();
        iter.recurse( subiter );
        return formatSimpleContainerIter( subiter, "(", ",", ")", depth+1 );
    }

    /*
     * Dictionary Entry
     */
    if ( signature[0] == '{' && signature[signature.length-1] == '}' )
    {
        DBus.RawMessageIter subiter = DBus.RawMessageIter();
        iter.recurse( subiter );

        var result = "";
        result += formatResult( subiter, depth+1 );
        result += ":";
        subiter.next();
        result += formatResult( subiter, depth+1 );
        return result;
    }

    /*
     * Variant
     */
    if ( signature == "v" )
    {
        DBus.RawMessageIter subiter = DBus.RawMessageIter();
        iter.recurse( subiter );
        var result = " ";
        result += formatResult( subiter, depth+1 );
        return result;
    }

    /*
     * Simple Type
     */
    return formatSimpleType( signature, iter );
}

static string formatSimpleType( string signature, DBus.RawMessageIter iter )
{
    switch ( signature )
    {
        case "y":
            uint8 i = 0;
            iter.get_basic( &i );
            return i.to_string();
        case "b":
            bool b = false;
            iter.get_basic( &b );
            return b.to_string();
        case "n":
            int16 i = 0;
            iter.get_basic( &i );
            return i.to_string();
        case "i":
            int i = 0;
            iter.get_basic( &i );
            return i.to_string();
        case "q":
            uint16 i = 0;
            iter.get_basic( &i );
            return i.to_string();
        case "x":
            int64 i = 0;
            iter.get_basic( &i );
            return i.to_string();
        case "u":
            uint32 i = 0;
            iter.get_basic( &i );
            return i.to_string();
        case "t":
            uint64 i = 0;
            iter.get_basic( &i );
            return i.to_string();
        case "d":
            double i = 0;
            iter.get_basic( &i );
            return i.to_string();
        case "s":
            unowned string s = null;
            iter.get_basic( &s );
            return @"\"$s\"";
        case "o":
            unowned string s = null;
            iter.get_basic( &s );
            return @"op'$s'";
        default:
#if DEBUG
            critical( @"signature $signature not yet handled" );
#endif
            return @"<?$signature?>";
    }
}

//===========================================================================
public class Argument : Object
{
    public Argument( string name, string typ )
    {
        this.name = name;
        this.typ = typ;
    }

    public bool appendToCall( string arg, DBus.RawMessage message )
    {
#if DEBUG
        debug( @"trying to parse argument $name of type $typ delivered as $arg" );
#endif
        switch ( typ )
        {
            case "y":
                uint8 value = (uint8)arg.to_int();
                assert( message.append_args( DBus.RawType.BYTE, ref value ) );
                break;
            case "b":
                bool value = ( arg == "true" || arg == "True" || arg == "1" );
                assert( message.append_args( DBus.RawType.BOOLEAN, ref value ) );
                break;
            case "n":
                int16 value = (int16)arg.to_int();
                assert( message.append_args( DBus.RawType.INT16, ref value ) );
                break;
            case "i":
                int value = arg.to_int();
                assert( message.append_args( DBus.RawType.INT32, ref value ) );
                break;
            case "q":
                uint16 value = (uint16)arg.to_int();
                assert( message.append_args( DBus.RawType.UINT16, ref value ) );
                break;
            case "u":
                uint32 value = (uint32)arg.to_long();
                assert( message.append_args( DBus.RawType.UINT32, ref value ) );
                break;
            case "t":
                uint64 value = (uint64)arg.to_long();
                assert( message.append_args( DBus.RawType.UINT64, ref value ) );
                break;
            case "d":
                double value = arg.to_double();
                assert( message.append_args( DBus.RawType.DOUBLE, ref value ) );
                break;
            case "s":
                assert( message.append_args( DBus.RawType.STRING, ref arg ) );
                break;
            case "o":
                assert( message.append_args( DBus.RawType.OBJECT_PATH, ref arg ) );
                break;
            default:
                stderr.printf( @"Unsupported type $typ\n" );
                return false;
        }
        return true;
    }

    public string name;
    public string typ;
}

//===========================================================================
public class Entity : Object
{
    public enum Typ
    {
        METHOD,
        SIGNAL,
        PROPERTY
    }

    public Entity( string name, Typ typ )
    {
        this.name = name;
        this.typ = typ;
    }

    public string to_string()
    {
        string line = "";

        switch ( typ )
        {
            case Typ.METHOD:   line = "[METHOD]    %s(%s) -> (%s)";
            break;
            case Typ.SIGNAL:   line = "[SIGNAL]    %s(%s)";
            break;
            case Typ.PROPERTY: line = "[PROPERTY]  %s(%s)";
            break;
            default:
                assert_not_reached();
        }

        string inargs = "";

        foreach ( var arg in inArgs )
        {
            inargs += " %s:%s,".printf( arg.typ, arg.name );
        }
        if ( inArgs.length() > 0 )
            ( (char[]) inargs )[inargs.length-1] = ' ';

        string outargs = "";

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

    public string inSignature()
    {
        var result = "";

        foreach ( var arg in inArgs )
        {
            result += arg.typ;
        }
        return result;
    }

    public string outSignature()
    {
        var result = "";

        foreach ( var arg in outArgs )
        {
            result += arg.typ;
        }
        return result;
    }

    public string name;
    public Typ typ;
    public List<Argument> inArgs;
    public List<Argument> outArgs;
}

//===========================================================================
public class Introspection : Object
{
    public List<string> nodes;
    public List<string> interfaces;
    public List<Entity> entitys;

    private string iface;
    private Entity entity;

    public Introspection( string xmldata )
    {
        //message( "introspection object created w/ xmldata: %s", xmldata );

        MarkupParser parser = { startElement, null, null, null, null };
        var mpc = new MarkupParseContext( parser, MarkupParseFlags.TREAT_CDATA_AS_TEXT, this, null );

        try
        {
            foreach ( var line in xmldata.split( "\n" ) )
            {
                if ( line[1] != '!' || line[0] != '"' )
                {
                    //message( "dealing with line '%s'", line );
                    mpc.parse( line, line.length );
                }
            }
        }
        catch ( MarkupError e )
        {
            stderr.printf( "[ERR]: Invalid introspection data\n" );
        }
    }

    public void handleAttributes( string[] attribute_names, string[] attribute_values )
    {
        string name = "none";
        string direction = "in";
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
        if ( direction == "in" )
            entity.inArgs.append( arg );
        else
            entity.outArgs.append( arg );
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
                entity = new Entity( "%s.%s".printf( iface, attribute_values[0] ), Entity.Typ.METHOD );
                entitys.append( entity );
                break;
            case "signal":
                entity = new Entity( "%s.%s".printf( iface, attribute_values[0] ), Entity.Typ.SIGNAL );
                entitys.append( entity );
                break;
            case "property":
                entity = new Entity( "%s.%s".printf( iface, attribute_values[0] ), Entity.Typ.PROPERTY );
                entitys.append( entity );
                handleAttributes( attribute_names, attribute_values );
                break;
            case "arg":
                assert( entity != null );
                handleAttributes( attribute_names, attribute_values );
                break;
            default:
#if DEBUG
                stderr.printf( @"[WARN]: Unknown introspection type $element_name; ignoring\n" );
#endif
                break;
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
            critical( "Dbus error: %s", e.message );
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
        _listObjects( busname, "/", ref allpaths );
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
        return false;

#endif
        return false;
    }

    private string appendPidToBusName( string name )
    {
        uint pid = 0;

        try
        {
            pid = busobj.GetConnectionUnixProcessID( name );
        }
        catch ( DBus.Error e )
        {
#if DEBUG
            debug( "%s", e.message );
#endif
        }
        return "%s (%s)".printf( name, pid > 0 ? pid.to_string() : "unknown" );
    }

    public List<string> _listBusNames( string prefix = "" )
    {
        string[] names = busobj.ListNames();
        List<string> sortednames = new List<string>();

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

    public void _listObjects( string busname, string path, ref List<string> result, string prefix = "" )
    {
        dynamic DBus.Object o = bus.get_object( busname, path, DBUS_INTERFACE_INTROSPECTABLE );

        if ( path.has_prefix( prefix ) )
        {
            result.append( path );
        }

        try
        {
            var idata = new Introspection( o.Introspect() );
            foreach ( var node in idata.nodes )
            {
                //message ( "node = '%s'", node );
                var nextnode = ( path == "/" ) ? "/%s".printf( node ) : "%s/%s".printf( path, node );
                //message( "nextnode = '%s'", nextnode );
                _listObjects( busname, nextnode, ref result, prefix );
            }
        }
        catch ( DBus.Error e )
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

        var names = new List<string>();
        _listObjects( busname, path, ref names );
        foreach ( var name in names )
        {
            stdout.printf( "%s\n", name );
        }
    }

    public List<string> _listInterfaces( string busname, string path, string? prefix = null, bool stripPropertiesAndSignals = false )
    {
        var result = new List<string>();
        dynamic DBus.Object o = bus.get_object( busname, path, DBUS_INTERFACE_INTROSPECTABLE );

        try
        {
            var idata = new Introspection( o.Introspect() );
            if ( idata.entitys.length() == 0 )
            {
                stderr.printf( "[ERR]: No introspection data at object '%s'\n", path );
                return result;
            }
            foreach ( var entity in idata.entitys )
            {
                if ( stripPropertiesAndSignals && entity.typ != Entity.Typ.METHOD )
                {
                    continue;
                }
                if ( prefix == null )
                {
                    result.append( entity.to_string() );
                }
                else
                {
                    if ( entity.name.has_prefix( prefix ) )
                    {
                        result.append( entity.name );
                    }
                }
            }
        }
        catch ( DBus.Error e )
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

        foreach ( var name in _listInterfaces( busname, path ) )
        {
            stdout.printf( "%s\n", name );
        }
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

        dynamic DBus.Object o = bus.get_object( busname, path, DBUS_INTERFACE_INTROSPECTABLE );

        try
        {
            var idata = new Introspection( o.Introspect() );
            if ( idata.entitys.length() == 0 )
            {
                stderr.printf( "[ERR]: No introspection data at object %s\n", path );
                return false;
            }

            foreach ( var entity in idata.entitys )
            {
                if ( entity.typ == Entity.Typ.METHOD && entity.name == method )
                {
                    var methodWithPoint = method.rchr( -1, '.' );
                    var baseMethod = methodWithPoint.substring( 1 );
                    var iface = method.substring( 0, method.length - baseMethod.length - 1 );

                    // check number of input params
                    if ( args.length != entity.inArgs.length() )
                    {
                        stderr.printf( "[ERR]: Need %u params for signature '%s', supplied %u\n", entity.inArgs.length(), entity.inSignature(), args.length );
                        return false;
                    }

                    // construct DBus Message arg by arg
                    var call = new DBus.RawMessage.call( busname, path, iface, baseMethod );
                    int i = 0;
                    foreach ( var inarg in entity.inArgs )
                    {
                        if ( inarg.appendToCall( args[i++], call ) )
                        {
#if DEBUG
                            debug( @"Argument $i parsed from commandline ok" );
#endif
                        }
                        else
                        {
                            return false;
                        }
                    }

                    DBus.RawError error = DBus.RawError();
                    DBus.RawConnection* connection = bus.get_connection();
                    DBus.RawMessage reply = connection->send_with_reply_and_block( call, 100000, ref error );

                    if ( error.is_set() )
                    {
#if DEBUG
                        stdout.printf( @"Method call done. Result:\nDBus Error $(error.name): $(error.message)\n" );
#else
                        stderr.printf( @"$(error.name): $(error.message)\n" );
#endif
                    }
                    else
                    {
#if DEBUG
                        stdout.printf( @"Method call done. Result:\n$(formatMessage(reply))\n" );
#else
                        stdout.printf( @"$(formatMessage(reply))\n" );
#endif
                    }
                    return true;
                }
            }

            stderr.printf( @"[ERR]: No method $method found at $path for $busname\n" );
        }
        catch ( DBus.Error e )
        {
            stderr.printf( "[ERR]: %s\n", e.message );
            return false;
        }
        return false;
    }

    public DBus.RawHandlerResult signalHandler( DBus.RawConnection conn, DBus.RawMessage message )
    {
#if DEBUG
        debug( "got message w/ type %d", message.get_type() );
#endif
        if ( message.get_type() != DBus.RawMessageType.SIGNAL )
        {
            return DBus.RawHandlerResult.NOT_YET_HANDLED;
        }

        var line = "[SIGNAL] %s.%s  %s  %s\n%s".printf(
          message.get_interface(),
          message.get_member(),
          message.get_path(),
          message.get_sender(),
          formatMessage( message ) );
        stdout.printf( @"$line\n" );

        return DBus.RawHandlerResult.HANDLED;
    }

    private string formatRule( string busname, string objectpath, string iface )
    {
        var rule = "type='signal'";

        if ( busname != "*" )
        {
            rule += @",sender='$busname'";
        }

        if ( objectpath != "*" )
        {
            rule += @",path='$objectpath'";
        }

        if ( iface != "*" )
        {
            rule += @",interface='$iface'";
        }

        return rule;
    }

    public void listenForSignals( string busname = "*", string objectpath = "*", string iface = "*" )
    {
        DBus.RawConnection* connection = bus.get_connection();
        connection->add_filter( signalHandler );
        DBus.RawError error = DBus.RawError();
        connection->add_match( formatRule( busname, objectpath, iface ), ref error );
        ( new MainLoop() ).run();
    }

    private bool isValidDBusName( string busname )
    {
        var parts = busname.split( "." );
        if ( parts.length < 2 )
        {
            return false;
        }
        if ( busname.has_prefix( "." ) )
        {
            return false;
        }
        if ( busname.has_suffix( "." ) )
        {
            return false;
        }
        return true;
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
                assert_not_reached();
                break;
            case 1:
                listObjects( args[0] );
                break;
            case 2:
                listInterfaces( args[0], args[1] );
                break;
            default:
                commands.callMethod( args[0], args[1], args[2], args[3:args.length] );
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
                    completions = commands._listBusNames( prefix );
                    break;
                case 2: /* object path */
                    completions = new List<string>();
                    commands._listObjects( parts[0], "/", ref completions, prefix );
                    break;
                case 3: /* interfaces (minus signals or properties) */
                    completions = commands._listInterfaces( parts[0], parts[1], prefix, true );
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

const OptionEntry[] options =
{
    { "show-anonymous", 'a', 0, OptionArg.NONE, ref showAnonymous, "Show anonymous names", null },
    { "show-pids", 'p', 0, OptionArg.NONE, ref showPIDs, "Show unix process IDs", null },
    { "listen", 'l', 0, OptionArg.NONE, ref listenerMode, "Listen for signals", null },
    { "system", 's', 0, OptionArg.NONE, ref useSystemBus, "Use System Bus", null },
    { "interactive", 'i', 0, OptionArg.NONE, ref interactive, "Enter interactive shell", null },
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

    commands = new Commands( useSystemBus ? DBus.BusType.SYSTEM : DBus.BusType.SESSION );

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
                commands.listObjects( args[1] );
            else
                commands.listenForSignals( args[1] );
            break;

        case 3:
            if ( !listenerMode )
                commands.listInterfaces( args[1], args[2] );
            else
                commands.listenForSignals( args[1], args[2] );
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
            var ok = commands.callMethod( args[1], args[2], args[3], restargs );
            return ok ? 0 : -1;
    }

    return 0;
}

