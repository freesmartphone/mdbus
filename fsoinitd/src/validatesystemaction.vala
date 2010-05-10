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
		if (Posix.getpid() != 1)
		{
			FsoFramework.theLogger.error("Not being executed as init");
			return false;
		}

		/* Assure that we started as root */
		if (Posix.getuid() == 1) 
		{
			FsoFramework.theLogger.error("Need to be root!");
			return false;
		}

		return true;
	}

	public bool reset()
	{
		/* do nothing */
		return true;
	}
}

} // namespace

