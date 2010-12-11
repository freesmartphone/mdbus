/*
 * Copyright (C) 2010 Simon Busch <morphis@gravedo.de>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */
 
public static class MsmUtil
{
    public static void handleMsmcommErrorMessage( Msmcomm.Error error ) throws FreeSmartphone.Error
    {
        var msg = @"Could not process command, got: $(error.message)";
        throw new FreeSmartphone.Error.INTERNAL_ERROR( msg );
    }
    
    public static string networkRegistrationStatusToString( Msmcomm.NetworkRegistrationStatus reg_status)
    {
        string result = "unknown";
        
        switch ( reg_status )
        {
            case Msmcomm.NetworkRegistrationStatus.HOME:
                result = "home";
                break;
            case Msmcomm.NetworkRegistrationStatus.ROAMING:
                result = "roaming";
                break;
            case Msmcomm.NetworkRegistrationStatus.SEARCHING:
                result = "searching";
                break;
            case Msmcomm.NetworkRegistrationStatus.DENIED:
                result = "denied";
                break;
        }
        
        return result;
    }
}
