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

using Gee;

/**
 * @class FsoGsm.Call
 **/
public class FsoGsm.Call
{
    public FreeSmartphone.GSM.CallDetail detail;

    public Call.newFromDetail( FreeSmartphone.GSM.CallDetail detail )
    {
        this.detail = detail;
    }

    public Call.newFromId( int id )
    {
        detail.id = id;
        detail.status = FreeSmartphone.GSM.CallStatus.RELEASE;
        detail.properties = new GLib.HashTable<string,GLib.Variant>( str_hash, str_equal );
    }

    public bool update_status( FreeSmartphone.GSM.CallStatus new_status )
    {
        var result = false;

        if ( this.detail.status != new_status )
        {
            this.detail.status = new_status;
            notify( this.detail );
            result = true;
        }

        return result;
    }

    public bool update( FreeSmartphone.GSM.CallDetail detail )
    {
        assert( this.detail.id == detail.id );
        var result = false;

        // Something has changed and we should notify somebody about his?
        if ( this.detail.status != detail.status )
        {
            notify( detail );
            result = true;
        }
        else if ( this.detail.properties.size() != detail.properties.size() )
        {
            notify( detail );
            result = true;
        }

        /*
        var iter = GLib.HashTableIter<string,GLib.Variant>( this.detail.properties );
        string key; Variant? v;
        while ( iter.next( out key, out v ) )
        {
            var v2 = detail.properties.lookup( key );
            if ( v2 == null || v != v2 )
            {
                notify( detail );
                return;
            }
        }
        */

        return result; 
    }

    private void notify( FreeSmartphone.GSM.CallDetail detail )
    {
        status_changed( detail.id, detail.status, detail.properties );
        this.detail = detail;
    }

    public signal void status_changed( int id, FreeSmartphone.GSM.CallStatus status, GLib.HashTable<string,Variant> properties );
}

/**
 * @class FsoGsm.CallInfo
 **/
public class FsoGsm.CallInfo : GLib.Object
{
    construct
    {
        cinfo = new GLib.HashTable<string,GLib.Variant>( str_hash, str_equal );
    }

    public CallInfo()
    {
    }

    public CallInfo.with_ctype( string ctype )
    {
        this.ctype = ctype;
    }

    public string ctype { get; set; default = ""; }
    public int id { get; set; default = 0; }
    public GLib.HashTable<string, GLib.Variant?> cinfo;
}

// vim:ts=4:sw=4:expandtab
