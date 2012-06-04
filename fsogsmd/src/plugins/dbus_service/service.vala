/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *                         Simon Busch <morphis@gravedo.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;

public class FsoGsm.Service : FsoFramework.AbstractObject
{
    protected FsoGsm.Modem modem;

    protected void checkAvailability( FsoGsm.Modem.Status required = FsoGsm.Modem.Status.ALIVE_NO_SIM ) throws FreeSmartphone.Error
    {
        if ( modem == null )
            throw new FreeSmartphone.Error.UNAVAILABLE( "There is no underlying hardware present... stop talking to a vapourware modem!" );

        if ( ( modem.status() < required ) || ( modem.status() >= FsoGsm.Modem.Status.SUSPENDING ) )
            throw new FreeSmartphone.Error.UNAVAILABLE( @"This function is not available while modem is in state $(modem.status())" );
    }

    public void assignModem( FsoGsm.Modem modem )
    {
        this.modem = modem;
    }

    public override string repr()
    {
        return @"<>";
    }
}

// vim:ts=4:sw=4:expandtab
