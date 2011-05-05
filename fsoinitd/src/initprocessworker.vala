/**
 * -- freesmartphone.org boot utility --
 *
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
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

namespace FsoInit
{

public class InitProcessWorker : GLib.Object
{
	private IActionQueue actionQueue;
	private BaseConfiguration configuration;

	construct
	{
		actionQueue = new ActionQueue();
	}

	public void setup()
	{
		configuration = createMachineConfiguration();
		FsoFramework.theLogger.info(@"created configuration for machine '$(configuration.name)'");

		FsoFramework.theLogger.info(@"register all actions for machine configuration '$(configuration.name)'");
		configuration.registerActionsInQueue(actionQueue);
	}

	public bool run()
	{
		assert(configuration != null);

		FsoFramework.theLogger.info(@"run all actions for machine configuration '$(configuration.name)'");
		return actionQueue.run();
	}
}


} // namespace

// vim:ts=4:sw=4:expandtab
