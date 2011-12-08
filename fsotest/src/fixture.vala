/*
 * Valadate - Unit testing library for GObject-based libraries.
 * Copyright (C) 2009  Jan Hudec <bulb@ucw.cz>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
 * License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using GLib;

namespace FsoTest
{
    /**
     * Marker interface for unit tests.
     *
     * To define a test suite, imlement this interface.
     * The runner will execute all methods whose names begin with "test_"
     * in that class, each on a separate instance.
     *
     * The set_up() method will be called before each test and
     * tear_down() will be called after. Since each test is run on
     * a separate instance, you can use construct block and destructor
     * with the same effect.
     *
     * [[warning:
     *   The constructor will ++not++ be called, because the object will
     *   be constructed using GLib.Object.newv. You have to use the
     *   //construct// block.
     * ]]
     *
     * Example:
     * {{{
     * class Test1 : Object, FsoTest.Fixture
     * {
     *     construct
     *     {
     *         stdout.printf ("Constructing fixture");
     *     }
     *
     *     ~Test1
     *     {
     *         stdout.printf ("Destroying fixture");
     *     }
     *
     *     public void test_1 ()
     *     {
     *         assert (0 != 1);
     *     }
     * }
     * }}}
     *
     * Test method declared async are also recognized and they are run under
     * main-loop until completion or timeout, which is taken from the
     * //timeout// property. Async test method can optionally have
     * a GLib.Cancellable argument, which will be cancelled when timeout
     * occurs.
     *
     * If you define some public constructible properties and for each
     * property define a static method named
     * "generate_"//property-name// returning a ValueArray, each test
     * will be called once for each value in the returned array. If you
     * define multiple property-generator pairs, the tests will be run
     * for each combination.
     */
    public abstract class Fixture : Object
    {
        /**
         * Called after construction before a test is run.
         *
         * You can use construct block (but not constructor) to the
         * same effect.
         */
        public virtual async void setup() {}

        public virtual bool run( TestManager test_manager )
        {
            return true;
        }

        /**
         * Called after a test is run before the object is destroyed.
         *
         * You can use destructor to the same effect.
         */
        public virtual void teardown() {}

        /**
         * Timeout for async tests.
         *
         * You can change this in constructor or set_up to define the timeout
         * for async tests in this class. Value is in milliseconds and
         * default to 5000ms.
         */
        public int timeout { get; set; default = 5000; }

        public string name { get; set; default = ""; }
    }
}
