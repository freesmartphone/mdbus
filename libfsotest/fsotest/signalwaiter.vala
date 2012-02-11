/*
 * (C) 2011 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

using GLib;

namespace FsoFramework.Test
{
    private class SignalWrapper
    {
        public Object emitter { get; set; }
        public string signame { get; set; default = ""; }
        public ulong id { get; set; }
        public int timeout { get; set; }
        public int catch_count { get; set; }

        public int callback()
        {
            catch_count++;
            triggered();
            return 0;
        }

        public void setup()
        {
            id = Signal.connect_swapped( emitter, signame, (Callback) SignalWrapper.callback, this );
            catch_count = 0;
        }

        public void release()
        {
            SignalHandler.disconnect( emitter, id );
        }

        public signal void triggered();
    }

    public class MultiSignalWaiter : GLib.Object
    {
        private GLib.List<SignalWrapper> signals = new GLib.List<SignalWrapper>();
        private uint succeeded_count = 0;
        private MainLoop mainloop;

        public void add_signal( Object emitter, string signame, int timeout = 200 )
        {
            var s = new SignalWrapper() { emitter = emitter, signame = signame, timeout = 200 };
            s.triggered.connect( () => {
                succeeded_count++;
                if ( succeeded_count == signals.length() )
                    mainloop.quit();
            } );
            signals.append( s );
        }

        public bool run( Block block, int timeout = 200 )
        {
            mainloop = new MainLoop(MainContext.default(), true);
            succeeded_count = 0;

            foreach ( var s in signals )
                s.setup();

            block();
            var t1 = Timeout.add( timeout, () => {
                mainloop.quit();
                return false;
            } );

            while ( mainloop.is_running() )
                mainloop.run();

            bool succeeded = true;
            foreach ( var s in signals )
            {
                s.release();
                if ( s.catch_count == 0 )
                    succeeded = false;
            }

            Source.remove( t1 );
            return succeeded;
        }
    }
}

// vim:ts=4:sw=4:expandtab
