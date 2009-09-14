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
 * Mediator Interface and Base Class
 **/

public abstract interface FsoGsm.Mediator : GLib.Object
{
}

public abstract class FsoGsm.AbstractMediator : FsoGsm.Mediator, GLib.Object
{
    protected void enqueue( FsoGsm.AtCommand command, string chars, FsoGsm.ResponseHandler handler )
    {
        debug( "enqueueing %s", Type.from_instance( command ).name() );
        var channel = theModem.channel("main");
        channel.enqueue( command, chars, handler );
    }
}
