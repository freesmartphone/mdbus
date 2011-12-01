/*
 * (C) 2011 Simon Busch <morphis@gravedo.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

/**
 * Provideds basic functionality to controll a service we will be used by a test cae or
 * one of it's dependency. This class does not deal with dbus service but with basic
 * functionality every service type needs.
 *
 * A service can be implemented as remote one or as local one. So a class which inherits
 * from the the BaseService class implement a service locally so no remote component is
 * needed.
 */
public abstract class FsoTest.BaseService : FsoFramework.AbstractObject
{
    /**
     * Name of the service associated with this class.
     */
    public string name { get; set; }

    /**
     * Services needed by this service to work. If this service is started all
     * dependencies are started as well in the order as they are specified in this array.
     */
    public string[] depends_on { get; set; }

    /**
     * Indicates wether the service is running and available or not.
     */
    public bool active { get; private set; default = false; }

    /**
     * Initialize a new service object.
     * @param name Name of the service
     */
    public BaseService( string name )
    {
        this.name = name;
    }

    /**
     * Starts the service. If the service is already running this will do nothing.
     */
    public abstract async void start();

    /**
     * Stops the service. If the service is already stopped this will do nothing.
     */
    public abstract async void stop();

    /**
     * Reset the service. If the service is not running this will do nothing.
     */
    public abstract async void reset();

    /**
     * Provide a textual representation for the object of this type of class.
     * @return Textual representation of this class
     */
    public override string repr()
    {
        return @"<>";
    }
}

// vim:ts=4:sw=4:expandtab
