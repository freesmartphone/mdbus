/**
 * -- freesmartphone.org boot utility --
 *
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 **/

GLib.MainLoop mainloop;

int main( string[] args ) 
{
	var bin = FsoFramework.Utility.programName();
	
	FsoFramework.theLogger.info("startup ...");
	mainloop = new GLib.MainLoop(null, false);
	
	if (Posix.getpid() != 1)
	{
		FsoFramework.theLogger.error("Running fsoinitd not as real init process (pid=1), is not supported currently");
		return -1;
	}

	var worker = new FsoInit.InitProcessWorker();
	worker.setup();
	worker.run();
	
	FsoFramework.theLogger.info( "%s => mainloop".printf( bin ) );
	mainloop.run();
	FsoFramework.theLogger.info( "mainloop => %s".printf( bin ) );

	FsoFramework.theLogger.info( "%s exit".printf( bin ) );
	
	return 0;
}

