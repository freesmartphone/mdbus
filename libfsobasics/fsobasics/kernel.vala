/*
 * Copyright (C) 2010-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace FsoFramework
{
    /**
     * @class Kernel26Module
     **/
    public class Kernel26Module
    {
        private string _name;

        public bool active { get; private set; default = false; }
        public bool available { get; private set; default = false; }
        public string name
        {
            get { return _name; }
            set { _name = value; checkAvailability(); }
        }
        public string arguments { get; set; default = ""; }

        //
        // private methods
        //

        private void checkAvailability()
        {
            var rc = Posix.system( @"/sbin/modinfo $(name)" );
            available = ( rc == 0 );
        }

        //
        // public methods
        //

        public Kernel26Module(string name)
        {
            this.name = name;
        }

        /**
         * Loads the named module into kernel space
         **/
        public bool load()
        {
            bool result = false;
            if ( available && !active )
            {
                var rc = Posix.system( @"/sbin/modprobe $(name) $(arguments)" );
                result = ( rc == 0 );
                active = result;
            }
            return result;
        }

        /**
         * Unloads the named module from kernel
         **/
        public bool unload()
        {
            bool result = false;
            if ( available && active )
            {
                var rc = Posix.system( @"/sbin/modprobe -r $(name)" );
                result = ( rc == 0 );
                active = false;
            }
            return result;
        }
    }
}

// vim:ts=4:sw=4:expandtab
