/**
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using GLib;

namespace FsoDevice {

/**
 * BasePowerControlResource: Exports a BasePowerControl instance via the DBus Resource API
 */
public class BasePowerControlResource : FsoFramework.AbstractDBusResource
{
    private weak ISimplePowerControl bpc;
    private FreeSmartphone.UsageResourcePolicy policy;

    public BasePowerControlResource( ISimplePowerControl bpc, string name, FsoFramework.Subsystem subsystem,
        FreeSmartphone.UsageResourcePolicy policy = FreeSmartphone.UsageResourcePolicy.AUTO )
    {
        base( name, subsystem );
        this.bpc = bpc;
        this.policy = policy;
    }

    public override async void enableResource() throws FreeSmartphone.ResourceError
    {
        logger.debug( "enabling..." );
        bpc.setPower( true );
    }

    public override async void disableResource()
    {
        logger.debug( "disabling..." );
        bpc.setPower( false );
    }

    public override async void suspendResource()
    {
        logger.debug( "suspending..." );
    }

    public override async void resumeResource()
    {
        logger.debug( "resuming..." );
    }

    public override FreeSmartphone.UsageResourcePolicy default_policy()
    {
        return policy;
    }
}


} /* namespace FsoDevice */

// vim:ts=4:sw=4:expandtab
