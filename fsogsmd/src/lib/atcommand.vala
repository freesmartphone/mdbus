/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

/**
 * At response codes
 **/
public enum FsoGsm.AtResponse
{
    VALID = 0,
    OK = 1,
    UNEXPECTED_LENGTH = 501,
    UNABLE_TO_PARSE = 502,
    ERROR = 503,
    CME_ERROR_START = 1000,
    CMS_ERROR_START = 2000,
    EXT_ERROR_START = 3000,
}

public abstract interface FsoGsm.AtCommand : GLib.Object
{
    public abstract void parse( string response ) throws AtCommandError;
    public abstract void parseTest( string response ) throws AtCommandError;
    public abstract bool is_valid_prefix( string line );

    public abstract FsoGsm.AtResponse validate( string[] response );
    public abstract FsoGsm.AtResponse validateTest( string[] response );

    public abstract FsoGsm.AtResponse validateOk( string[] response );
}

public abstract class FsoGsm.AbstractAtCommand : FsoGsm.AtCommand, GLib.Object
{
    protected Regex re;
    protected Regex tere;
    protected MatchInfo mi;
    protected string[] prefix;
    protected int length;

    construct
    {
        message( "%s()", Type.from_instance( this ).name() );
        length = 1;
    }

    ~AbstractAtCommand()
    {
        message( "~%s()", Type.from_instance( this ).name() );
    }

    public virtual void parse( string response ) throws AtCommandError
    {
        bool match;
        match = re.match( response, 0, out mi );

        if ( !match || mi == null )
            throw new AtCommandError.UNABLE_TO_PARSE( "%s does not match against RE %s".printf( response, re.get_pattern() ) );
    }

    public virtual void parseTest( string response ) throws AtCommandError
    {
        bool match;
        match = tere.match( response, 0, out mi );

        if ( !match || mi == null )
            throw new AtCommandError.UNABLE_TO_PARSE( "%s does not match against RE %s".printf( response, tere.get_pattern() ) );
    }

    /**
     * Validate the terminal response for this At command
     **/
    public virtual FsoGsm.AtResponse validateOk( string[] response )
    {
        if ( response[response.length-1] != "OK" )
        {
            debug( "Did not receive OK for AT command w/ pattern %s", re.get_pattern() );
            //FIXME: Parse and do something meaningful with the result
            return AtResponse.ERROR;
        }
        else
        {
            return AtResponse.OK;
        }
    }

    /**
     * Validate a response for this At command
     **/
    public virtual FsoGsm.AtResponse validate( string[] response )
    {
        var status = validateOk( response );
        if ( status != AtResponse.OK )
        {
            return status;
        }

        // check whether we have received enough lines
        if ( response.length <= length )
        {
            debug( "Unexpected length for AT command w/ pattern %s", re.get_pattern() );
            return AtResponse.UNEXPECTED_LENGTH;
        }

        try
        {
            parse( response[0] );
        }
        catch ( AtCommandError e )
        {
            debug( "Unexpected format for AT command w/ pattern %s", re.get_pattern() );
            return AtResponse.UNABLE_TO_PARSE;
        }
        debug( "Did receive a valid response to AT command w/ pattern %s", re.get_pattern() );
        return AtResponse.VALID;
    }

    /**
     * Validate a test response for this At command
     **/
    public virtual FsoGsm.AtResponse validateTest( string[] response )
    {
        var status = validateOk( response );
        if ( status != AtResponse.OK )
        {
            return status;
        }

        // second, check whether we have received enough lines
        if ( response.length <= length )
        {
            debug( "Unexpected length for AT command w/ pattern %s", tere.get_pattern() );
            return AtResponse.UNEXPECTED_LENGTH;
        }

        try
        {
            parseTest( response[0] );
        }
        catch ( AtCommandError e )
        {
            debug( "Unexpected format for AT command w/ pattern %s", tere.get_pattern() );
            return AtResponse.UNABLE_TO_PARSE;
        }
        debug( "Did receive a valid response to AT command w/ pattern %s", tere.get_pattern() );
        return AtResponse.VALID;
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
            testx += """(?P<min>\d+)-(?P<max>\d+)""";
        }
        else
        {
            assert_not_reached();
        }
        if ( !prefixoptional )
        {
            prefix = { name + ": " };
        }
        re = new Regex( regex );
        tere = new Regex( testx );
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

public class FsoGsm.NullAtCommand : FsoGsm.AbstractAtCommand
{
}
