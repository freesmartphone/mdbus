/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace FsoGsm
{
    private FsoGsm.LowLevel createLowLevelFromType( string lowleveltype )
    {
        FsoGsm.LowLevel lowlevel;
        string typename = "none";

        switch ( lowleveltype )
        {
            case "motorola_ezx":
                typename = "LowLevelMotorolaEZX";
                break;
            case "openmoko":
                typename = "LowLevelOpenmoko";
                break;
            case "nokia900":
                typename = "LowLevelNokia900";
                break;
            case "samsung_crespo":
                typename = "LowLevelSamsungCrespo";
                break;
            case "gta04":
                typename = "LowLevelGTA04";
                break;
            default:
                FsoFramework.theLogger.warning( @"Invalid lowlevel_type $lowleveltype; vendor specifics will NOT be available" );
                lowleveltype = "none";
                break;
        }

        if ( lowleveltype != "none" )
        {
            var lowlevelclass = Type.from_name( typename );
            if ( lowlevelclass == Type.INVALID  )
            {
                FsoFramework.theLogger.warning( @"Can't find plugin for lowlevel_type $lowleveltype; vendor specifics will NOT be available" );
                lowlevel = new FsoGsm.NullLowLevel();
            }
            else
            {
                lowlevel = Object.new( lowlevelclass ) as FsoGsm.LowLevel;
                FsoFramework.theLogger.info( @"Ready. Using lowlevel plugin $lowleveltype to handle vendor specifics" );
            }
        }
        else
        {
            lowlevel = new FsoGsm.NullLowLevel();
        }

        return lowlevel;
    }

    private FsoGsm.IPdpHandler createPdpHandlerFromType( string pdphandlertype )
    {
        FsoGsm.IPdpHandler pdphandler;
        string typename = "none";

        switch ( pdphandlertype )
        {
            case "ppp":
                typename = "PdpPpp";
                break;
            case "mux":
                typename = "PdpPppMux";
                break;
            case "qmi":
                typename = "PdpQmi";
                break;
            case "ippp":
                typename = "PdpPppInternal";
                break;
            case "nokia_isi":
                typename = "PdpNokiaIsi";
                break;
            case "samsung_ipc":
                typename = "SamsungPdpHandler";
                break;
            case "option_gtm601":
                typename = "PdpOptionGtm601";
                break;
            default:
                FsoFramework.theLogger.warning( @"Invalid pdp_type $pdphandlertype; data connectivity will NOT be available" );
                pdphandlertype = "none";
                break;
        }

        if ( pdphandlertype != "none" )
        {
            var pdphandlerclass = Type.from_name( typename );
            if ( pdphandlerclass == Type.INVALID  )
            {
                FsoFramework.theLogger.warning( @"Can't find plugin for pdp_type $pdphandlertype; data connectivity will NOT be available" );
                pdphandler = new FsoGsm.NullPdpHandler();
            }
            else
            {
                pdphandler = Object.new( pdphandlerclass ) as FsoGsm.PdpHandler;
                FsoFramework.theLogger.info( @"Ready. Using pdp plugin $pdphandlertype to handle data connectivity" );
            }
        }
        else
        {
            pdphandler = new FsoGsm.NullPdpHandler();
        }

        return pdphandler;
    }
}

// vim:ts=4:sw=4:expandtab
