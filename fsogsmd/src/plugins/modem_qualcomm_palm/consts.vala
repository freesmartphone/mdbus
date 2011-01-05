/*
 * Copyright (C) 2010-2011 Simon Busch <morphis@gravedo.de>
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

namespace Msmcomm
{
    public string deviceFunctionalityStatusToString( ModemOperationMode status )
    {
        switch ( status )
        {
            case ModemOperationMode.OFFLINE:
                return "airplane";
            case ModemOperationMode.ONLINE:
                return "full";
            default:
                return "unknown";
        }
    }
    
    public void checkPhonebookBookType(PhonebookBookType bookType) throws FreeSmartphone.Error
    {
        if ( bookType == Msmcomm.PhonebookBookType.UNKNOWN )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Invalid category" );
        }
    }

    public PhonebookBookType stringToPhonebookBookType( string bookType )
    {
        var result = Msmcomm.PhonebookBookType.UNKNOWN;

        // FIXME add more phonebook types !!!
        switch ( bookType )
        {
            case "fixed":
                result = Msmcomm.PhonebookBookType.FDN;
                break;
            case "abbreviated":
                result = Msmcomm.PhonebookBookType.ADN;
                break;
        }
    
        return result;
    }
    
    public string phonebookBookTypeToString( PhonebookBookType bookType )
    {
        var result = "unknown";
        
        switch ( bookType )
        {
            case Msmcomm.PhonebookBookType.FDN:
                result = "fixed";
                break;
            case Msmcomm.PhonebookBookType.ADN:
                result = "abbreviated";
                break;
        }
        
        return result;
    }
    
    public string networkRegistrationStatusToString(Msmcomm.NetworkRegistrationStatus reg_status)
    {
        string result = "";
        
        switch (reg_status)
        {
            case Msmcomm.NetworkRegistrationStatus.NO_SERVICE:
                result = "no service";
                break;
            case Msmcomm.NetworkRegistrationStatus.HOME:
                result = "home";
                break;
            case Msmcomm.NetworkRegistrationStatus.SEARCHING:
                result = "searching";
                break;
            case Msmcomm.NetworkRegistrationStatus.DENIED:
                result = "denied";
                break;
            case Msmcomm.NetworkRegistrationStatus.ROAMING:
                result = "roaming";
                break;
            case Msmcomm.NetworkRegistrationStatus.UNKNOWN:
                result = "unknown";
                break;
        }
        
        return result;
    }
    
} // namespace Msm
