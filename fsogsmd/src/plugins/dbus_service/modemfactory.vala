/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using GLib;

public class FsoGsm.ModemFactory : GLib.Object
{
    private static Type typeNameToClassType( string modemtype )
    {
        string typename;

        switch ( modemtype )
        {
            case "cinterion_mc75":
                typename = "CinterionMc75Modem";
                break;
            case "dummy":
                typename = "DummyModem";
                break;
            case "freescale_neptune":
                typename = "FreescaleNeptuneModem";
                break;
            case "nokia_isi":
                typename = "NokiaIsiModem";
                break;
            case "singleline":
                typename = "SinglelineModem";
                break;
            case "ti_calypso":
                typename = "TiCalypsoModem";
                break;
            case "qualcomm_htc":
                typename = "QualcommHtcModem";
                break;
            case "qualcomm_palm":
                typename = "QualcommPalmModem";
                break;
            case "samsung":
                typename = "SamsungModem";
                break;
            case "option_gtm601":
                typename = "Gtm601Modem";
                break;
            default:
                FsoFramework.theLogger.error( @"Unsupported modem_type $modemtype" );
                return Type.INVALID;
        }

        return Type.from_name( typename );
    }

    public static bool validateModemType( string modemtype )
    {
        return typeNameToClassType( modemtype ) != Type.INVALID;
    }

    public static FsoGsm.Modem? createFromTypeName( string modemtype )
    {
        FsoGsm.Modem? modem = null;

        var modemclass = typeNameToClassType( modemtype );
        if ( modemclass == Type.INVALID  )
        {
            FsoFramework.theLogger.error( @"Can't find modem for modem_type $modemtype; corresponding modem plugin loaded?" );
            return null;
        }

        modem = (FsoGsm.Modem) Object.new( modemclass );
        return modem;
    }
}

// vim:ts=4:sw=4:expandtab
