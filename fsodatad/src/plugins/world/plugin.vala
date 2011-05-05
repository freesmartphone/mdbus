/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

namespace World {
    const string MODULE_NAME = "fsodata.world";
}

class World.Info : FreeSmartphone.Data.World, FsoFramework.AbstractObject
{
    FsoFramework.Subsystem subsystem;

    public Info( FsoFramework.Subsystem subsystem )
    {
        this.subsystem = subsystem;
        subsystem.registerObjectForService<FreeSmartphone.Data.World>( FsoFramework.Data.ServiceDBusName, FsoFramework.Data.WorldServicePath, this );
        logger.info( @"Created" );
    }

    public override string repr()
    {
        return "<>";
    }

    //
    // DBus API (org.freesmartphone.Data.World)
    //
    public async FreeSmartphone.Data.WorldCountry[] get_all_countries() throws DBusError, IOError
    {
        var countries = new FreeSmartphone.Data.WorldCountry[] {};

        foreach ( var country in FsoData.MBPI.Database.instance().allCountries().values )
        {
            if ( country.name == null )
            {
                country.name = @"Unknown:$(country.code)";
            }
            countries += FreeSmartphone.Data.WorldCountry( country.code, country.name );
        }
        return countries;
    }

    public async string get_country_code_for_mcc_mnc( string mcc_mnc ) throws FreeSmartphone.Error, DBusError, IOError
    {
        var mcc = "%c%c%c".printf( (int)mcc_mnc[0], (int)mcc_mnc[1], (int)mcc_mnc[2] );
        var prefixccode = "";
#if DEBUG
        debug( @"Looking for = $(mcc_mnc)" );
#endif
        foreach ( var country in FsoData.MBPI.Database.instance().allCountries().values )
        {
#if DEBUG
            debug( @"Country = $(country.code)" );
#endif
            foreach ( var provider in country.providers.values )
            {
#if DEBUG
                debug( @"Provider = $(provider.name)" );
#endif
                foreach ( var code1 in provider.codes )
                {
#if DEBUG
                    debug( @"Code = $(code1)" );
#endif
                    if ( code1 == mcc_mnc )
                    {
#if DEBUG
                        debug( @"Full match with country code $(country.code)" );
#endif
                        return country.code;
                    }
                    else if ( ( prefixccode == "" ) && code1.has_prefix( mcc ) )
                    {
#if DEBUG
                        debug( @"Prefix match with country code $(country.code)" );
#endif
                        prefixccode = country.code;
                    }
                }
            }
        }
#if DEBUG
        debug( @"No country/provider found with MCC $mcc" );
#endif
        return prefixccode;
    }

    public async GLib.HashTable<string,string> get_timezones_for_country_code( string country_code ) throws FreeSmartphone.Error, DBusError, IOError
    {
        var country = FsoData.MBPI.Database.instance().allCountries()[country_code];
        if ( country == null )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( @"Can't find a country for code '$country_code'" );
        }
        var timezones = new GLib.HashTable<string,string>( GLib.str_hash, GLib.str_equal );
        foreach ( var key in country.timezones.keys )
        {
            timezones.insert( key, country.timezones[key] );
        }
        return timezones;
    }

    public async FreeSmartphone.Data.WorldConnectivityAccessPoint[] get_apns_for_mcc_mnc( string mcc_mnc ) throws FreeSmartphone.Error, DBusError, IOError
    {
        var result = new FreeSmartphone.Data.WorldConnectivityAccessPoint[] {};

        var mcc = "%c%c%c".printf( (int)mcc_mnc[0], (int)mcc_mnc[1], (int)mcc_mnc[2] );

        foreach ( var country in FsoData.MBPI.Database.instance().allCountries().values )
        {
            foreach ( var provider in country.providers.values )
            {
                foreach ( var code in provider.codes )
                {
                    if ( code == mcc_mnc )
                    {
                        foreach ( var apn in provider.gsm.values )
                        {
                            var name = provider.name;
                            if ( apn.description != null )
                            {
                                name += " (%s)".printf( apn.description );
                            }
                            result += FreeSmartphone.Data.WorldConnectivityAccessPoint( name, apn.name ?? "unknown", apn.user ?? "", apn.password ?? "", "", "" );
                        }
                    }
                }
            }
        }

        return result;
    }
}

World.Info instance;

/**
 * This function gets called on plugin initialization time.
 * @return the name of your plugin here
 * @note that it needs to be a name in the format <subsystem>.<plugin>
 * else your module will be unloaded immediately.
 **/
public static string fso_factory_function( FsoFramework.Subsystem subsystem ) throws Error
{
    instance = new World.Info( subsystem );
    return World.MODULE_NAME;
}

[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsotime.world fso_register_function" );
}

/**
 * This function gets called on plugin load time.
 * @return false, if the plugin operating conditions are present.
 * @note Some versions of glib contain a bug that leads to a SIGSEGV
 * in g_module_open, if you return true here.
 **/
/*public static bool g_module_check_init( void* m )
{
    var ok = FsoFramework.FileHandling.isPresent( Kernel26.SYS_CLASS_LEDS );
    return (!ok);
}
*/

// vim:ts=4:sw=4:expandtab
