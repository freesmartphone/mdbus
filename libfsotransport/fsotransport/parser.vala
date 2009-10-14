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

public abstract interface FsoFramework.Parser : GLib.Object
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

public class FsoFramework.BaseParser : FsoFramework.Parser, GLib.Object
{
    protected Parser.HaveCommandFunc haveCommand;
    protected Parser.ExpectedPrefixFunc expectedPrefix;
    protected Parser.SolicitedCompletedFunc solicitedCompleted;
    protected Parser.UnsolicitedCompletedFunc unsolicitedCompleted;

    public void setDelegates( Parser.HaveCommandFunc haveCommand,
                              Parser.ExpectedPrefixFunc expectedPrefix,
                              Parser.SolicitedCompletedFunc solicitedCompleted,
                              Parser.UnsolicitedCompletedFunc unsolicitedCompleted )
    {
        this.haveCommand = haveCommand;
        this.expectedPrefix = expectedPrefix;
        this.solicitedCompleted = solicitedCompleted;
        this.unsolicitedCompleted = unsolicitedCompleted;
    }

    public int feed( void* data, int len )
    {
        return 0;
    }
}
