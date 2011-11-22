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
     * Implementing a filter which accepts one or more children and combines there results
     * by a logical operator.
     **/
    public abstract class LogicalFilter : BaseFilter
    {
        private Gee.ArrayList<BaseFilter> children;

        construct
        {
            children = new Gee.ArrayList<BaseFilter>();
        }

        protected abstract bool process_operator(bool current, bool value);

        /**
         * Ask the filter to accept another filter as child.
         *
         * @param child The child the filter should decide about to accept
         * @return If the filter accepts the child it returns true oterwise false
         **/
        public override bool accept_child(BaseFilter child)
        {
            children.add(child);
            return true;
        }

        /**
         * Filter the supplied set of key-value pairs and check if they meet the
         * conditions of this filter.
         *
         * @param data The hash map containing the key-value pairs to filter
         * @return If all pairs meets the conditions of the filter it returns true
         * otherwise false
         **/
        public override bool process(Gee.HashMap<string,GLib.Variant?> data)
        {
            var result = false;

            foreach (var child in children)
            {
                result = process_operator(result, child.process(data));
            }

            return result;
        }
    }
}
