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

/**
 * @interface FsoFramework.IParserDelegate
 *
 * Interface to describe various actions delegated from the parser.
 **/
public interface FsoFramework.IParserDelegate : GLib.Object
{
    public abstract bool onParserHaveCommand();
    public abstract bool onParserIsExpectedPrefix( string line );
    public abstract void onParserSolicitedCompleted( string[] response );
    public abstract void onParserUnsolicitedCompleted( string[] response );
}

/**
 * @interface FsoFramework.Parser
 *
 * The Parser Interface
 **/
public abstract interface FsoFramework.Parser : GLib.Object
{
    /**
     * Set the delegate
     **/
    public abstract void setDelegate( IParserDelegate? d );

    /**
     * Feed data into the parser.
     **/
    public abstract int feed( void* data, int len );
}

/**
 * Base Parser Class
 **/
public class FsoFramework.BaseParser : FsoFramework.Parser, GLib.Object
{
    protected IParserDelegate? _delegate;

    public void setDelegate( IParserDelegate? d )
    {
        _delegate = d;
    }

    public virtual int feed( void* data, int len )
    {
        assert_not_reached();
    }
}

/**
 * @class FsoFramework.NullParser
 *
 * The NullParser swallows everything.
 **/
public class FsoFramework.NullParser : FsoFramework.BaseParser
{
    public override int feed( void *data, int len )
    {
        return 0;
    }
}

/**
 * @class FsoFramework.LineByLineParser
 *
 * The LineByLineParser reads data byte-by-byte until it encounters the terminal symbol.
 **/
public class FsoFramework.LineByLineParser : FsoFramework.BaseParser
{
    private string termination;
    private char[] curline;
    private uint index;
    private uint matched;
    private bool swallow;

    //
    // private API
    //

    private void resetLine()
    {
#if DEBUG
        debug( "reset line" );
#endif
        curline = {};
        index = 0;
        matched = 0;
    }

    private void feedCharacter( char c )
    {
        if ( c == termination[index] )
        {
            if ( !swallow )
            {
                curline += c;
            }
            index++;
            matched++;
            if ( matched == termination.length )
            {
                endofline();
            }
        }
        else
        {
            index = 0;
            matched = 0;
#if DEBUG
            debug( "adding '%c' to '%s'", c, (string)curline );
#endif
            curline += c;
        }
    }

    private void endofline()
    {
        curline += 0x0; // we want to treat it as a string
#if DEBUG
        debug( "line completed: '%s'", (string)curline );
#endif

        if ( !_delegate.onParserHaveCommand() )
        {
            _delegate.onParserUnsolicitedCompleted( { (string)curline } );
        }
        else
        {
            _delegate.onParserSolicitedCompleted( { (string)curline } );
        }
        resetLine();
    }

    //
    // public API
    //

    public LineByLineParser( string termination = "\r\n", bool swallow = true )
    {
        this.termination = termination;
        this.swallow = swallow;
        resetLine();
    }

    public override int feed( char* data, int len )
    {
        for ( int i = 0; i < len; ++i )
        {
            char c = *data++;
            feedCharacter( c );
        }

        return 0;
    }
}

// vim:ts=4:sw=4:expandtab
