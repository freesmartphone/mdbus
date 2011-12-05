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
 * Base class for a class describing tests for one object. Each test method within this
 * class should be named as the following example: test_<description>
 * A test method has no parameters and not return value.
 */
public abstract class FsoTest.BaseTest : FsoFramework.AbstractObject
{
    /**
     * Setup anything needed for execution of the test methods itself.
     */
    public abstract void setup() throws GLib.Error;

    /**
     * Tear down anything used by the test.
     */
    public abstract void teardown() throws GLib.Error;

    /**
     * Provide a textual representation of ourself.
     * @return Texttual representation of an object of this class
     */
    public override string repr()
    {
        return @"<>";
    }
}

// vim:ts=4:sw=4:expandtab
