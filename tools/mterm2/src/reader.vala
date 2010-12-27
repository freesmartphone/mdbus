/*
 * (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 *
 */

using GLib;
using FsoFramework;

const string HISTORY_PATH = "%s/.mterm2.history";
const string PROGRAM_NAME = "mterm2";

public class Reader
{
    private unowned GLib.Thread thread;
    private unowned Transport transport;

    public Reader( Transport transport )
    {
        this.transport = transport;
        thread = GLib.Thread.create<void*>( run, true );
    }

    private void* run()
    {
        Readline.initialize();
        Readline.readline_name = PROGRAM_NAME;
        Readline.terminal_name = Environment.get_variable( "TERM" );

        Readline.History.read( HISTORY_PATH.printf( Environment.get_variable( "HOME" ) ) );
        Readline.History.max_entries = 512;

        while ( true )
        {
            var line = Readline.readline( "" );
            if ( line == null ) // ctrl-d
            {
                quitWithMessage( ":::Offline." );
                return null;
            }
            else
            {
                Readline.History.add( line );
                transport.write( line + "\r\n", (int)line.length + 2 );
            }
        }
        return null;
    }

    ~Reader()
    {
        Readline.History.write( HISTORY_PATH.printf( Environment.get_variable( "HOME" ) ) );
    }
}
