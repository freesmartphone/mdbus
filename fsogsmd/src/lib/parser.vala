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

public abstract interface FsoGsm.Parser : GLib.Object
{
    public delegate bool HaveCommandFunc();
    public delegate bool ExpectedPrefixFunc( string line );
    public delegate void SolicitedCompletedFunc( string[] response );
    public delegate void UnsolicitedCompletedFunc( string[] response );

    public abstract void setDelegates( HaveCommandFunc haveCommand,
                                       ExpectedPrefixFunc expectedPrefix,
                                       SolicitedCompletedFunc solicitedCompleted,
                                       UnsolicitedCompletedFunc unsolicitedCompleted );

    public abstract int feed( void* data, int len );
}

public class FsoGsm.NullParser : FsoGsm.Parser, GLib.Object
{
    public void setDelegates( Parser.HaveCommandFunc haveCommand,
                              Parser.ExpectedPrefixFunc expectedPrefix,
                              Parser.SolicitedCompletedFunc solicitedCompleted,
                              Parser.UnsolicitedCompletedFunc unsolicitedCompleted )
    {
    }

    public int feed( void* data, int len )
    {
        return 0;
    }
}

public class FsoGsm.StateBasedAtParser : FsoGsm.Parser, GLib.Object
{
    State state = State.INVALID;
    char[] curline;
    string[] solicited;
    string[] unsolicited;
    bool pendingPDU;

    Parser.HaveCommandFunc haveCommand;
    Parser.ExpectedPrefixFunc expectedPrefix;
    Parser.SolicitedCompletedFunc solicitedCompleted;
    Parser.UnsolicitedCompletedFunc unsolicitedCompleted;

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
        return resetLine();
    }

    public State resetLine( bool pending_pdu = false )
    {
        curline = {};
        return pending_pdu ? State.INLINE : State.START;
    }

    //FIXME: This works around a problem in Vala as we can't define a HashTable full with function pointers atm.
    public State dispatch( State curstate, char c )
    {
        debug( "state = %d, feeding '%c'", curstate, c );
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
        curline += 0x0; // we want to treat it as a string
        debug( "line completed: '%s'", (string)curline );

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
        debug( "endoflinePerhapsSolicited" );
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

        if ( !expectedPrefix( (string)curline ) )
        {
            return endoflineSurelyUnsolicited();
        }

        pendingPDU = hasSolicitedPdu();
        solicited += (string)curline;
        return resetLine( pendingPDU );
    }

    public State endoflineSurelySolicited()
    {
        debug( "endoflineSurelySolicited" );
        solicited += (string)curline;

        debug( "is final response. solicited response with %d lines", solicited.length );
        solicitedCompleted( solicited ); //TODO: rather call in idle mode or will this confuse everything?
        return resetAll();
    }

    public State endoflineSurelyUnsolicited()
    {
        debug( "endoflineSurelyUnsolicited" );
        unsolicited += (string)curline;

        if ( pendingPDU )
        {
            debug( "pending PDU received; unsolicited response completed." );
            pendingPDU = false;
            unsolicitedCompleted( unsolicited );
            return resetAll( false );
        }

        if ( hasUnsolicitedPdu() )
        {
            debug( "unsolicited response pending PDU..." );
            pendingPDU = true;
            return resetLine( pendingPDU );
        }

        debug( "unsolicited response completed." );
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

    public void setDelegates( Parser.HaveCommandFunc haveCommand,
                                       Parser.ExpectedPrefixFunc expectedPrefix,
                                       Parser.SolicitedCompletedFunc solicitedCompleted,
                                       Parser.UnsolicitedCompletedFunc unsolicitedCompleted )
    {
        this.haveCommand = haveCommand;
        this.expectedPrefix = expectedPrefix;
        this.solicitedCompleted = solicitedCompleted;
        this.unsolicitedCompleted = unsolicitedCompleted;

        state = resetAll();
    }

    public int feed( char* data, int len )
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

