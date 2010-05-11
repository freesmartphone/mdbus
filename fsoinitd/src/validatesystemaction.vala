/**
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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

namespace FsoInit 
{

public class ValidateSystemAction : IAction, GLib.Object
{
	public string name { get { return "ValidateSystemAction"; } }

	public string to_string() 
	{
		return @"[$(name)] :: no parameters";
	}

	public bool run()
	{
		/* Assure that we are the number one */
		var res = (int) Posix.getpid();
		if (!Util.CHECK( () => { return res > -1; }, "Not being executed as init"))
			return false;

		/* Assure that we started as root */
		res = (int) Posix.getuid();
		if (!Util.CHECK( () => { return res > -1; }, "Need to be root!"))
			return false;

		/* Become the leader of a new session and process group */
		Posix.setsid();

		/* Set root directory to be at the right place if we were 
		 * started from some strange place 
		 */
		 res = Posix.chdir("/");
		 if (!Util.CHECK( () => { return res > -1; }, "Cannot set root directory!"))
			return false;

		/* Set path for binaries */
		var path = "/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin";
		GLib.Environment.set_variable("PATH", path, true);

		return true;
	}

	public bool reset()
	{
		/* do nothing */
		return true;
	}
}

} // namespace

