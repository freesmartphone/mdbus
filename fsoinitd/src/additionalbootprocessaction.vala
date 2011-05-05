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

namespace FsoInit {

public class AdditionalBootProcessAction : IAction, GLib.Object
{
	public string name { get { return "AdditionalBootProcessAction"; } }

	public string to_string()
	{
		return @"[$(name)] :: no parameter";
	}

	public bool run()
	{
		if (FsoFramework.FileHandling.isPresent("/etc/rc.local")) {
			var res = Posix.system("/bin/sh /etc/rc.local &");

			if (res < 0)
			{
				FsoFramework.theLogger.error("Could not launch additional boot process from /etc/rc.local");
				return false;
			}
		}

		return true;
	}

	public bool reset()
	{
		// FIXME what to do here?
		return true;
	}
}

} // namespace

// vim:ts=4:sw=4:expandtab
