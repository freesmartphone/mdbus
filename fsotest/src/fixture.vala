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
        private class TestInfo : GLib.Object
        {
            public string name { get; set; default = "unknown"; }
            public bool is_async { get; set; default = false; }
            public AsyncBegin async_func { get; set; }
            public AsyncFinish async_end { get; set; }
            public TestMethod sync_func { get; set; }
        }

        private GLib.List<TestInfo> tests = new GLib.List<TestInfo>();

        /**
         * Add a asynchronous test method for execution. Each test method will be executed
         * separately when calling the run method of this class.
         */
        protected void add_async_test( string name, AsyncBegin async_func, AsyncFinish async_end )
        {
            tests.append( new TestInfo() {
                name = name,
                is_async = true,
                async_func = async_func,
                async_end = async_end
            } );
        }

        protected void add_test( string name, TestMethod func )
        {
            tests.append( new TestInfo() {
                name = name,
                sync_func = func
            } );
        }

        private bool run_async_test( TestManager test_manager, TestInfo test )
        {
            return test_manager.run_test_method( test.name,
                () => wait_for_async( 200, test.async_func, test.async_end ) );
        }

        private bool run_test( TestManager test_manager, TestInfo test )
        {
            return test_manager.run_test_method( test.name, test.sync_func );
        }

        //
        // public API
        //

        /**
         * Timeout for async tests.
         */
        public int timeout { get; set; default = 5000; }

        /**
         * Name for this test fixture.
         */
        public string name { get; protected set; default = ""; }

        /**
         * Called after construction before a test is run.
         */
        public virtual async void setup() {}

        /**
         * Execute all tests while collecting their results.
         */
        public bool run( TestManager test_manager )
        {
            foreach ( var test in tests )
            {
                if ( test.is_async )
                    run_async_test( test_manager, test );
                else run_test( test_manager, test );
            }
            return true;
        }

        /**
         * Called after a test is run before the object is destroyed.
         */
        public virtual void teardown() {}
    }
}
