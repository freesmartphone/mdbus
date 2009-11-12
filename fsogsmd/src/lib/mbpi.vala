/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

/**
 * Mobile Broadband Provider Info
 **/
namespace MBPI {

public class Country
{
    public Country()
    {
        providers = new Gee.HashMap<string,Provider>();
    }
    public string name;
    public Gee.HashMap<string,Provider> providers;
}

public class Provider
{
    public Provider()
    {
        codes = new Gee.ArrayList<string>();
        gsm = new Gee.HashMap<string,AccessPoint>();
        cdma = new Gee.HashMap<string,AccessPoint>();
    }
    public string name;
    /* mnc mcc this provider has assigned */
    public Gee.ArrayList<string> codes;
    /* gsm access points this provider operates */
    public Gee.HashMap<string,AccessPoint> gsm;
    /* cdma access points this provider operates */
    public Gee.HashMap<string,AccessPoint> cdma;
}

public class AccessPoint
{
    public AccessPoint()
    {
        dns = new Gee.ArrayList<string>();
    }
    public string description;
    public string name;
    public string user;
    public string passsword;
    public Gee.ArrayList<string> dns;
}

public class Database : FsoFramework.AbstractObject
{
    public Gee.HashMap<string,Country> countries;

    private Country country;
    private Provider provider;
    private AccessPoint accesspoint;
    private bool gsm;
    private int depth;

    private static Database _instance;

    private Database()
    {
        load();
    }

    public override string repr()
    {
        return countries == null ? "<null>" : "<loaded>";
    }

    private void load()
    {
        countries = new Gee.HashMap<string,Country>();
        
        var doc = Xml.Parser.parse_file( Config.MBPI_DATABASE_PATH );
        if ( doc == null)
        {
            logger.warning( "Could not load mobile broadband provider info from $(Config.MBPI_DATABASE)" );
            return;
        }
        
        var root = doc->get_root_element();
        if ( root == null )
        {
            delete doc;
            warning( "Could not parse mobile broadband provider file" );
            return;
        }

        parseNode( root );

        delete doc;
    }

    private void parseNode( Xml.Node* node )
    {
        depth++;
        var name = node->name;
        var content = node->get_content();

        var props = new Gee.HashMap<string,string>();
        for ( var prop = node->properties; prop != null; prop = prop->next)
        {
            props[prop->name] = prop->children->content;
        }
        debug( @"node $name" );

        switch ( name )
        {
            case "serviceproviders":
                handleChildren( node );
                break;
            case "country":
                country = new Country() { name = props["code"] };
                handleChildren( node );
                countries[country.name] = country;
                debug( @"new country $(country.name)" );
                break;
            case "provider":
                provider = new Provider();
                handleChildren( node );
                country.providers[provider.name] = provider;
                debug( @"new provider $(provider.name)" );               
                break;
            case "gsm":
                gsm = true;
                handleChildren( node );
                break;
            case "cdma":
                gsm = false;
                handleChildren( node );
                break;
            case "network-id":
                provider.codes.add( props["mcc"] + props["mnc"] );
                break;
            case "apn":
                accesspoint = new AccessPoint() { name = props["value"] };
                handleChildren( node );
                if ( gsm )
                {
                    provider.gsm[accesspoint.name] = accesspoint;
                    debug( @"new apn $(accesspoint.name)" );               
                }
                else
                {
                    debug( "CDMA APN FIXME" );
                }
                break;
            case "name":
                if ( depth == 4 /* Provider Name */ )
                {
                    provider.name = content;
                }
                else
                {
                    accesspoint.description = content;
                }
                break;
            case "username":
                accesspoint.user = content;
                break;
            case "password":
                accesspoint.passsword = content;
                break;
            case "dns":
                accesspoint.dns.add( content );
                break;
            default:
                debug( @"ignoring unknown node name $name" );
                break;
        }
        depth--;
    }

    private void handleChildren( Xml.Node* node )
    {
        for ( var iter = node->children; iter != null; iter = iter->next )
        {
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;

            var node_name = iter->name;
            var node_content = iter->get_content();
            //debug( @"node $node_name, content $(node_content.escape(""))" );
            
            parseNode( iter );
        }
    }

    //
    // public API
    //
    public static Database instance()
    {
        if ( _instance == null )
        {
            _instance = new Database();
        }
        return _instance;
    }

    public Gee.Map<string,Provider> providersForCountry( string code )
    {
        var country = countries[code];
        if ( country == null )
        {
            return null;
        }
        return country.providers;
    }

    public Gee.Map<string,AccessPoint> accessPointsForMccMnc( string mccmnc )
    {
        foreach ( var country in countries.values )
        {
            foreach ( var provider in country.providers.values )
            {
                if ( mccmnc in provider.codes )
                {
                    return provider.gsm;
                }
            }
        }
        return null;
    }  
}

} /* namespace */
