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

/**
 * AT Command Interface and Abstract Base Class.
 *
 * The AtCommand class encapsulate generation and parsing of every kind of AT
 * command strings. To generate a command, use issue() or query(). The response
 * is to be fed into the parse() method. At commands are parsed using regular
 * expressions. The resulting fields are then picked into member variables.
 **/

public errordomain FsoGsm.AtCommandError
{
    UNABLE_TO_PARSE,
}

public abstract interface FsoGsm.AtCommand : GLib.Object, FsoGsm.AtCommandQueueCommand
{
    /* CommandQueueCommand */
    public abstract uint get_timeout();
    public abstract uint get_retry();
    public abstract string get_prefix();
    public abstract string get_postfix();
    public abstract bool is_valid_prefix( string line );

    /* AtCommand */
    public abstract void parse( string response ) throws AtCommandError;
    public abstract void parseMulti( string[] response ) throws AtCommandError;
    public abstract void parseTest( string response ) throws AtCommandError;

    /* Encoding/Decoding */
    public abstract string encodeString( string str );
    public abstract string decodeString( string str );

    public abstract Constants.AtResponse validate( string[] response );
    public abstract Constants.AtResponse validateTest( string[] response );
    public abstract Constants.AtResponse validateUrc( string response );
    public abstract Constants.AtResponse validateUrcPdu( string[] response );
    public abstract Constants.AtResponse validateOk( string[] response );
    public abstract Constants.AtResponse validateMulti( string[] response );
}

public abstract class FsoGsm.AbstractAtCommand : GLib.Object, FsoGsm.AtCommandQueueCommand, FsoGsm.AtCommand
{
    protected Regex re;
    protected Regex tere;
    protected MatchInfo mi;
    protected string[] prefix;
    protected int length;

    construct
    {
        length = 1;
    }

    ~AbstractAtCommand()
    {
#if DEBUG
        warning( "DESTRUCT %s", Type.from_instance( this ).name() );
#endif
    }

    public string encodeString( string str )
    {
        if ( str == null || str == "" )
            return "";

        var data = theModem.data();
        switch ( data.charset )
        {
            case "UCS2":
                var res = Conversions.utf8_to_ucs2( str );
                return ( res != null ) ? res : "";
            case "HEX":
                var res = Conversions.utf8_to_gsm( str );
                return ( res != null ) ? res : "";
            default:
                return str;
        }
    }

    public string decodeString( string str )
    {
        if ( str == null )
            return "";
        if ( str.length == 0 )
            return "";

        var data = theModem.data();
        switch ( data.charset )
        {
            case "UCS2":
                var res = Conversions.ucs2_to_utf8( str );
                return ( res != null ) ? res : "";
            case "HEX":
                var res = Conversions.gsm_to_utf8( str );
                return ( res != null ) ? res : "";
            default:
                return str;
        }
    }

    public virtual void parse( string response ) throws AtCommandError
    {
        bool match;
        match = re.match( response, 0, out mi );

        if ( !match || mi == null )
        {
            theModem.logger.debug( @"Parsing error: '$response' does not match '$(re.get_pattern())'" );
            throw new AtCommandError.UNABLE_TO_PARSE( "" );
        }
    }

    public virtual void parseTest( string response ) throws AtCommandError
    {
        bool match;
        match = tere.match( response, 0, out mi );

        if ( !match || mi == null )
        {
            theModem.logger.debug( @"Parsing error: '$response' does not match '$(tere.get_pattern())'" );
            throw new AtCommandError.UNABLE_TO_PARSE( "" );
        }
    }

    public virtual void parseMulti( string[] response ) throws AtCommandError
    {
        assert_not_reached(); // pure virtual method
    }

    /**
     * Validate the terminal response for this At command
     *
     * Does NOT parse!
     **/
    public virtual Constants.AtResponse validateOk( string[] response )
    {
        var statusline = response[response.length-1];
        //FIXME: Handle nonverbose mode as well
        if ( statusline == "OK" )
        {
            return Constants.AtResponse.OK;
        }

        if ( statusline == "CONNECT" )
        {
            return Constants.AtResponse.CONNECT;
        }

        assert( theModem.logger.debug( @"Did not receive OK (instead '$statusline') for $(Type.from_instance(this).name())" ) );
        var errorcode = 0;

        if ( ! ( ":" in statusline ) )
        {
            return Constants.AtResponse.ERROR;
        }

        if ( statusline.has_prefix( "+CMS" ) )
        {
            errorcode += (int)Constants.AtResponse.CMS_ERROR_START;
            errorcode += (int)statusline.split( ":" )[1].to_int();
            return (Constants.AtResponse)errorcode;
        }
        else if ( statusline.has_prefix( "+CME" ) )
        {
            errorcode += (int)Constants.AtResponse.CME_ERROR_START;
            errorcode += (int)statusline.split( ":" )[1].to_int();
            return (Constants.AtResponse)errorcode;
        }
        else if ( statusline.has_prefix( "+EXT" ) )
        {
            errorcode += (int)Constants.AtResponse.EXT_ERROR_START;
            errorcode += (int)statusline.split( ":" )[1].to_int();
            return (Constants.AtResponse)errorcode;
        }
        return Constants.AtResponse.ERROR;
    }

    /**
     * Parse actual response to this At command and validate
     **/
    public virtual Constants.AtResponse validate( string[] response )
    {
        var status = validateOk( response );
        if ( status != Constants.AtResponse.OK )
        {
            return status;
        }

        // check whether we have received enough lines
        if ( response.length <= length )
        {
            theModem.logger.warning( @"Unexpected length $(response.length) for $(Type.from_instance(this).name())" );
            return Constants.AtResponse.UNEXPECTED_LENGTH;
        }

        try
        {
            parse( response[0] );
        }
        catch ( AtCommandError e )
        {
            theModem.logger.warning( @"Unexpected format for $(Type.from_instance(this).name())" );
            return Constants.AtResponse.UNABLE_TO_PARSE;
        }
        assert( theModem.logger.debug( @"Did receive a valid response for $(Type.from_instance(this).name())" ) );
        return Constants.AtResponse.VALID;
    }

    /**
     * Validate a test response for this At command
     **/
    public virtual Constants.AtResponse validateTest( string[] response )
    {
        var status = validateOk( response );
        if ( status != Constants.AtResponse.OK )
        {
            return status;
        }

        // second, check whether we have received enough lines
        if ( response.length <= length )
        {
            theModem.logger.warning( @"Unexpected test length $(response.length) for $(Type.from_instance(this).name())" );
            return Constants.AtResponse.UNEXPECTED_LENGTH;
        }

        try
        {
            parseTest( response[0] );
        }
        catch ( AtCommandError e )
        {
            assert( theModem.logger.debug( @"Unexpected test format for $(Type.from_instance(this).name())" ) );
            return Constants.AtResponse.UNABLE_TO_PARSE;
        }
        assert( theModem.logger.debug( @"Did receive a valid test response for $(Type.from_instance(this).name())" ) );
        return Constants.AtResponse.VALID;
    }

    /**
     * Validate a multiline response for this At command
     **/
    public virtual Constants.AtResponse validateMulti( string[] response )
    {
        var status = validateOk( response );
        if ( status != Constants.AtResponse.OK )
        {
            return status;
        }
        // <HACK>
        response.length--;
        // </HACK>
        try
        {
            // response[0:-1]?
            parseMulti( response );
            // <HACK>
            response.length++;
            // </HACK>
        }
        catch ( AtCommandError e )
        {
            // <HACK>
            response.length++;
            // </HACK>
            theModem.logger.warning( @"Unexpected format for $(Type.from_instance(this).name())" );
            return Constants.AtResponse.UNABLE_TO_PARSE;
        }
        assert( theModem.logger.debug( @"Did receive a valid response for $(Type.from_instance(this).name())" ) );
        return Constants.AtResponse.VALID;
    }

    /**
     * Validate an URC for this At command
     **/
    public virtual Constants.AtResponse validateUrc( string response )
    {
        try
        {
            parse( response );
        }
        catch ( AtCommandError e )
        {
            theModem.logger.warning( @"Unexpected format for $(Type.from_instance(this).name())" );
            return Constants.AtResponse.UNABLE_TO_PARSE;
        }
        assert( theModem.logger.debug( @"Did receive a valid response for $(Type.from_instance(this).name())" ) );
        return Constants.AtResponse.VALID;
    }

    /**
     * Validate an URC w/ PDU for this At command
     **/
    public virtual Constants.AtResponse validateUrcPdu( string[] response )
    {
        // check whether we have received enough lines
        if ( response.length < 2 )
        {
            theModem.logger.warning( @"Unexpected length $(response.length) for $(Type.from_instance(this).name())" );
            return Constants.AtResponse.UNEXPECTED_LENGTH;
        }

        try
        {
            parseMulti( response );
        }
        catch ( AtCommandError e )
        {
            theModem.logger.warning( @"Unexpected format for $(Type.from_instance(this).name())" );
            return Constants.AtResponse.UNABLE_TO_PARSE;
        }
        assert( theModem.logger.debug( @"Did receive a valid response for $(Type.from_instance(this).name())" ) );
        return Constants.AtResponse.VALID;
    }

    protected string to_string( string name )
    {
        var res = mi.fetch_named( name );
        if ( res == null )
            return ""; // indicates parameter not present
        return res;
    }

    protected int to_int( string name )
    {
        var res = mi.fetch_named( name );
        if ( res == null )
            return -1; // indicates parameter not present
        return res.to_int();
    }

    public virtual uint get_timeout()
    {
        return 2 * 60;
    }

    public virtual uint get_retry()
    {
        return 3;
    }

    public virtual string get_prefix()
    {
        return "AT";
    }

    public virtual string get_postfix()
    {
        return "\r\n";
    }

    public bool is_valid_prefix( string line )
    {
        if ( prefix == null ) // free format
            return true;
        for ( int i = 0; i < prefix.length; ++i )
        {
            if ( line.has_prefix( prefix[i] ) )
                return true;
        }
        return false;
    }
}

public class FsoGsm.V250terCommand : FsoGsm.AbstractAtCommand
{
    public string name;

    public V250terCommand( string name )
    {
        this.name = name;
        prefix = { "+ONLY_TERMINAL_SYMBOLS_ALLOWED" };
    }

    public string execute()
    {
        return name;
    }
}

public class FsoGsm.SimpleAtCommand<T> : FsoGsm.AbstractAtCommand
{
    private string name;
    /* regular operation */
    public T value;

    /* for test command */
    public string righthandside;
    public int min;
    public int max;

    public SimpleAtCommand( string name, bool prefixoptional = false )
    {
        this.name = name;
        var regex = prefixoptional ? """(\%s:\ )?""".printf( name ) : """\%s:\ """.printf( name );
        var testx = prefixoptional ? """(\%s:\ )?""".printf( name ) : """\%s:\ """.printf( name );

        if ( typeof(T) == typeof(string) )
        {
            regex += """"?(?P<righthandside>[^"]*)"?""";
            testx += """"?(?P<righthandside>.*)"?""";
        }
        else if ( typeof(T) == typeof(int) )
        {
            regex += """(?P<righthandside>\d+)""";
            testx += """\((?P<min>\d+)-(?P<max>\d+)\)""";
        }
        else
        {
            assert_not_reached();
        }
        if ( !prefixoptional )
        {
            prefix = { name + ": " };
        }
        try
        {
            re = new Regex( regex );
            tere = new Regex( testx );
        }
        catch ( GLib.Error e )
        {
            assert_not_reached(); // fail here, if regex is invalid
        }
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );
        if ( typeof(T) == typeof(string) )
        {
            value = to_string( "righthandside" );
        }
        else if ( typeof(T) == typeof(int) )
        {
            value = to_int( "righthandside" );
        }
        else
        {
            assert_not_reached();
        }
    }

    public override void parseTest( string response ) throws AtCommandError
    {
        base.parseTest( response );
        if ( typeof(T) == typeof(string) )
        {
            righthandside = to_string( "righthandside" );
        }
        else if ( typeof(T) == typeof(int) )
        {
            min = to_int( "min" );
            max = to_int( "max" );
        }
        else
        {
            assert_not_reached();
        }
    }

    public string execute()
    {
        return name;
    }

    public string query()
    {
        return name + "?";
    }

    public string test()
    {
        return name + "=?";
    }

    public string issue( T val )
    {
        if ( typeof(T) == typeof(string) )
        {
            return "%s=\"%s\"".printf( name, (string)val );
        }
        else if ( typeof(T) == typeof(int) )
        {
            return "%s=%d".printf( name, (int)val );
        }
        else
        {
            assert_not_reached();
        }
    }

}

public class FsoGsm.TwoParamsAtCommand<T1,T2> : FsoGsm.AbstractAtCommand
{
    private string name;
    /* regular operation */
    public T1 value1;
    public T2 value2;

    public TwoParamsAtCommand( string name, bool prefixoptional = false )
    {
        this.name = name;
        var regex = prefixoptional ? """(\%s:\ )?""".printf( name ) : """\%s:\ """.printf( name );
        var testx = prefixoptional ? """(\%s:\ )?""".printf( name ) : """\%s:\ """.printf( name );

        if ( typeof(T1) == typeof(string) )
        {
            regex += """"?(?P<arg1>[^"]*)"?""";
            testx += """"?(?P<arg1>.*)"?""";
        }
        else if ( typeof(T1) == typeof(int) )
        {
            regex += """(?P<arg1>\d+)""";
            testx += """\((?P<min1>\d+)-(?P<max1>\d+)\)""";
        }
        else
        {
            assert_not_reached();
        }

        if ( typeof(T2) == typeof(string) )
        {
            regex += ""","?(?P<arg2>[^"]*)"?""";
            testx += ""","?(?P<arg2>.*)"?""";
        }
        else if ( typeof(T2) == typeof(int) )
        {
            regex += """,(?P<arg2>\d+)""";
            testx += """,\((?P<min2>\d+)-(?P<max2>\d+)\)""";
        }
        else
        {
            assert_not_reached();
        }

        if ( !prefixoptional )
        {
            prefix = { name + ": " };
        }
        try
        {
            re = new Regex( regex );
            tere = new Regex( testx );
        }
        catch ( GLib.Error e )
        {
            assert_not_reached(); // fail here, if regex is invalid
        }
    }

    public override void parse( string response ) throws AtCommandError
    {
        base.parse( response );

        if ( typeof(T1) == typeof(string) )
        {
            value1 = to_string( "arg1" );
        }
        else if ( typeof(T1) == typeof(int) )
        {
            value1 = to_int( "arg1" );
        }
        else
        {
            assert_not_reached();
        }

        if ( typeof(T2) == typeof(string) )
        {
            value2 = to_string( "arg2" );
        }
        else if ( typeof(T2) == typeof(int) )
        {
            value2 = to_int( "arg2" );
        }
        else
        {
            assert_not_reached();
        }
    }

    public string execute()
    {
        return name;
    }

    public string query()
    {
        return name + "?";
    }

    public string test()
    {
        return name + "=?";
    }

    public string issue( T1 val1, T2 val2 )
    {
        var cmd = @"$name=";

        if ( typeof(T1) == typeof(string) )
        {
            cmd += "\"%s\"".printf( (string)val1 );
        }
        else if ( typeof(T1) == typeof(int) )
        {
            cmd += "%d".printf( (int)val1 );
        }
        else
        {
            assert_not_reached();
        }

        if ( typeof(T2) == typeof(string) )
        {
            cmd += ",\"%s\"".printf( (string)val2 );
        }
        else if ( typeof(T2) == typeof(int) )
        {
            cmd += ",%d".printf( (int)val2 );
        }
        else
        {
            assert_not_reached();
        }

        return cmd;
    }

}

/**
 * @class FsoGsm.CustomAtCommand
 *
 * Instances of CustomAtCommand can be used, when you have to wrap a command
 * that does not require special parsing or is cheap expensive to (re)create.
 * These classes must not be added to the common command table, hence can not
 * be created by the atCommandFactory() method in the base modem class.
 **/
public class FsoGsm.CustomAtCommand : FsoGsm.AbstractAtCommand
{
    public CustomAtCommand( string name = "", bool prefixoptional = false )
    {
        if ( !prefixoptional )
        {
            prefix = { name + ": " };
        }
    }
}
