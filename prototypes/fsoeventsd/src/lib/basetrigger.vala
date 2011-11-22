/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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
 */

namespace FsoEvents
{
    /**
     * Delegate for a method to be executed when event for the trigger occurs.
     **/
    public delegate void TriggerHandlerFunc(Gee.HashMap<string,GLib.Variant?> data);

    /**
     * Representing the base class for a trigger object. A trigger is the initial event
       for a rule to execute.
     **/
    public abstract class BaseTrigger : FsoFramework.AbstractObject
    {
        protected TriggerHandlerFunc handler;

        construct
        {
            handler = null;
        }

        /**
         * Textual representation of this class
         **/
        public override string repr()
        {
            return @"<>";
        }

        /**
         * Connect a callback function to the trigger to be executed when the event for
         * the trigger occurs.
         **/
        public void connect_handler(TriggerHandlerFunc handler)
        {
            this.handler = handler;
        }
    }
}
