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

public class FsoGsm.HtcAtParser : FsoFramework.BaseParser
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
        // This state accounts for special HTC intermediate responses such as '[WCDMA] Current RRC Status = 0'
        START_HTC_BOGUS_BRACKET_LINE,
        V0_RESULT,
        ECHO_A,
        ECHO_INLINE,
        CONTINUATION,
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
        debug( "state = %s, feeding '%s'", FsoFramework.StringHandling.enumToString( typeof(State), curstate ), s );
#endif
        switch (curstate)
        {
            case State.START:
                return start( c );
            case State.START_R:
                return start_r( c );
            case State.V0_RESULT:
                return v0_result( c );
            case State.START_HTC_BOGUS_BRACKET_LINE:
                return start_htc_bogus_bracket_line( c );
            case State.ECHO_A:
                return echo_a( c );
            case State.ECHO_INLINE:
                return echo_inline( c );
            case State.CONTINUATION:
                return continuation( c );
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
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
                return State.V0_RESULT;
            case '\r':
                return State.START_R;
            case 'A':
            case 'a':
                return State.ECHO_A;
            case '[':
                return State.START_HTC_BOGUS_BRACKET_LINE;
            case '+':
                warning( "AT violation. Unsolicited without \\r\\n header (ignoring). Your modem sucks." );
                curline = { '+' };
                return State.INLINE;
        }
        return State.INVALID;
    }

    public State start_htc_bogus_bracket_line( char c )
    {
        switch (c)
        {
            case '\r':
                return State.START_R;
        }
        return State.START_HTC_BOGUS_BRACKET_LINE;
    }

    public State echo_a( char c )
    {
        switch ( c )
        {
            case 'T':
            case 't':
                warning( "Detected E1 mode (echo); ignoring, but please turn that off!" );
                return State.ECHO_INLINE;
        }
        return State.INVALID;
    }

    public State echo_inline( char c )
    {
        switch ( c )
        {
            case '\r':
                return State.START;
            default:
                return State.ECHO_INLINE;
        }
    }

    public State v0_result( char c )
    {
        switch ( c )
        {
            case '\r':
                warning( "Detected V0 mode (nonverbose). Ignoring, but please turn that off!" );
                curline += 'O';
                curline += 'K';
                return endofline();
            default:
                return State.INVALID;
        }
    }

    public State continuation( char c )
    {
        switch (c)
        {
            case ' ':
                curline = { '>', ' ' };
                return endoflineSurelySolicited();
            default:
                return State.INVALID;
        }
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
            case '>':
                return State.CONTINUATION;
            case '\r':
                // HTC madness bug in ATV1, does not include the mandatory \n
                // when the terminal response is an error message
                if ( curline.length > 11 &&
                     curline[0] == '+' && curline[1] == 'C' && curline[2] == 'M' &&
                     curline[5] == 'E' && curline[6] == 'R' && curline[7] == 'R' )
                {
                    return endofline();
                }
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
#if DEBUG
        debug( "endoflinePerhapsSolicited: detected pending PDU" );
#endif
            solicited += (string)curline;
            pendingPDU = false;
            return resetLine();
        }

        var prefixExpected = expectedPrefix( (string)curline );
#if DEBUG
        debug( "prefix expected = %s", prefixExpected.to_string() );
#endif
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

    public HtcAtParser()
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
