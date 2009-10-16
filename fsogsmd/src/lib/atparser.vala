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

public class FsoGsm.StateBasedAtParser : FsoFramework.BaseParser
{
    State state = State.INVALID;
    char[] curline;
    string[] solicited;
    string[] unsolicited;
    bool pendingPDU;

    string[] final_responses = {
        "OK",
        "ERROR",
        "+CME ERROR",
        "+CMS ERROR",
        "+EXT ERROR",
        "BUSY",
        "CONNECT",
        "NO ANSWER",
        "NO CARRIER",
        "NO DIALTONE"
    };

    string[] unsolicited_pdu = {
        "+CBM: ",
        "+CDS: ",
        "+CMT: "
    };

    string[] solicited_pdu = {
        "+CMGL: ",
        "+CMGR: "
    };

    protected bool isFinalResponse()
    {
        foreach( var line in final_responses )
        {
            if ( ((string)curline).has_prefix( line ) )
                return true;
        }
        return false;
    }

    protected bool hasUnsolicitedPdu()
    {
        foreach( var line in unsolicited_pdu )
        {
            if ( ((string)curline).has_prefix( line ) )
                return true;
        }
        return false;
    }

    protected bool hasSolicitedPdu()
    {
        foreach( var line in solicited_pdu )
        {
            if ( ((string)curline).has_prefix( line ) )
                return true;
        }
        return false;
    }

    public enum State
    {
        INVALID,
        START,
        START_R,
        INLINE,
        INLINE_R,
    }

    public State resetAll( bool soli = true )
    {
        unsolicited = {};
        if ( soli )
            solicited = {};
        return resetLine( true );
    }

    public State resetLine( bool end = false )
    {
        curline = {};
        return end ? State.START : State.INLINE;
    }

    //FIXME: This works around a problem in Vala as we can't define a HashTable full with function pointers atm.
    public State dispatch( State curstate, char c )
    {
#if DEBUG
        string s;
        if ( c == '\n' )
            s = "\\n";
        else if ( c == '\r' )
            s = "\\r";
        else
            s = "%c".printf( c );
        debug( "state = %d, feeding '%s'", curstate, s );
#endif
        switch (curstate)
        {
            case State.START:
                return start( c );
            case State.START_R:
                return start_r( c );
            case State.INLINE:
                return inline( c );
            case State.INLINE_R:
                return inline_r( c );
            default:
                assert_not_reached();
        }
        return State.INVALID;
    }

    //
    // Here comes the states
    //
    public State start( char c )
    {
        switch (c)
        {
            case '\r':
                return State.START_R;
        }
        return State.INVALID;
    }

    public State start_r( char c )
    {
        switch (c)
        {
            case '\n':
                return State.INLINE;
        }
        return State.INVALID;
    }

    public State inline( char c )
    {
        switch (c)
        {
            case '\r':
                return State.INLINE_R;
            default:
                curline += c;
                return State.INLINE;
        }
        return State.INVALID;
    }

    public State inline_r( char c )
    {
        switch (c)
        {
            case '\r':
                warning( "StateBasedAtParser: Multiple \r found; ignoring." );
                return State.INLINE_R;
            case '\n':
                return endofline();
        }
        return State.INVALID;
    }

    //
    // Here comes the type of line computation on end of line
    //
    public State endofline()
    {
        // skip empty lines
        if ( curline.length == 0 )
            return State.INLINE;

        curline += 0x0; // we want to treat it as a string
#if DEBUG
        debug( "line completed: '%s'", (string)curline );
#endif

        if ( !haveCommand() )
        {
            return endoflineSurelyUnsolicited();
        }
        else
        {
            return endoflinePerhapsSolicited();
        }
    }

    public State endoflinePerhapsSolicited()
    {
#if DEBUG
        debug( "endoflinePerhapsSolicited" );
#endif
        if ( isFinalResponse() )
        {
            return endoflineSurelySolicited();
        }

        if ( pendingPDU )
        {
            solicited += (string)curline;
            pendingPDU = false;
            return resetAll();
        }

        var prefixExpected = expectedPrefix( (string)curline );

        //message( @"Prefix expected: $(expectedPrefix((string)curline))" );
        message( "Prefix expected = %s".printf( prefixExpected.to_string() ) );

        if ( !expectedPrefix( (string)curline ) )
        {
            return endoflineSurelyUnsolicited();
        }

        pendingPDU = hasSolicitedPdu();
        solicited += (string)curline;
        return resetLine();
    }

    public State endoflineSurelySolicited()
    {
#if DEBUG
        debug( "endoflineSurelySolicited" );
#endif
        solicited += (string)curline;
#if DEBUG
        debug( "is final response. solicited response with %d lines", solicited.length );
#endif
        solicitedCompleted( solicited ); //TODO: rather call in idle mode or will this confuse everything?
        return resetAll();
    }

    public State endoflineSurelyUnsolicited()
    {
#if DEBUG
        debug( "endoflineSurelyUnsolicited" );
#endif
        unsolicited += (string)curline;

        if ( pendingPDU )
        {
#if DEBUG
            debug( "pending PDU received; unsolicited response completed." );
#endif
            pendingPDU = false;
            unsolicitedCompleted( unsolicited );
            return resetAll( false );
        }

        if ( hasUnsolicitedPdu() )
        {
#if DEBUG
            debug( "unsolicited response pending PDU..." );
#endif
            pendingPDU = true;
            return resetLine();
        }
#if DEBUG
        debug( "unsolicited response completed." );
#endif
        unsolicitedCompleted( unsolicited );
        return resetAll( false );  // do not clear solicited responses; we might have sneaked in-between
    }

    //=====================================================================//
    // PUBLIC API
    //=====================================================================//

    public StateBasedAtParser()
    {
        state = resetAll();
    }

    public override int feed( char* data, int len )
    {
        assert( len > 0 );
        for ( int i = 0; i < len; ++i )
        {
            char c = *data++;
            state = dispatch( state, c );
        }
        return state;
    }
}

