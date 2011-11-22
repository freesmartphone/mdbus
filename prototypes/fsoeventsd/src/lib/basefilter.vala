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
     * Representing the base class for a filter object. A filter is a condition for a
     * {@link Rule} to be executed.
     **/
    public abstract class BaseFilter : FsoFramework.AbstractObject
    {
        /**
         * Ask the filter to accept another filter as child.
         *
         * @param child The child the filter should decide about to accept
         * @return If the filter accepts the child it returns true oterwise false
         **/
        public virtual bool accept_child(BaseFilter child)
        {
            return false;
        }

        /**
         * Filter the supplied set of key-value pairs and check if they meet the
         * conditions of this filter.
         *
         * @param data The hash map containing the key-value pairs to filter
         * @return If all pairs meets the conditions of the filter it returns true
         * otherwise false
         **/
        public abstract bool process(Gee.HashMap<string,GLib.Variant?> data);

        /**
         * Textual representation of this class
         **/
        public override string repr()
        {
            return @"<>";
        }
    }
}
