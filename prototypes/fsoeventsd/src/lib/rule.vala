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
     *
     **/
    public class Rule : FsoFramework.AbstractObject
    {
        public BaseFilter filter { get; set; }
        public BaseTrigger trigger { get; set; }
        public string name { get; set; }

        /**
         * React on events from the trigger.
         *
         * @param data The data supplied by the trigger with the data of the event
         **/
        private void handle_trigger_event(Gee.HashMap<string,GLib.Variant?> data)
        {
            if (filter == null || filter.process(data))
            {
                // FIXME executed our actions which we don't have right now :)
            }
        }

        /**
         * Textual representation of this class
         **/
        public override string repr()
        {
            return @"<$name>";
        }
    }
}
