/*
 * Copyright (C) 2009-2012 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *               2012 Simon Busch <morphis@gravedo.de>
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

public interface FsoGsm.ICallDriver : GLib.Object
{
    public abstract async void dial( string number, string type ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void hold_all_active() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void release_all_held() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void release_all_active() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void create_conference() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void transfer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void deflect( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;

    public abstract async void cancel_outgoing_with_id( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
    public abstract async void reject_incoming_with_id( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error;
}

public class NullCallDriver : FsoGsm.ICallDriver, GLib.Object
{
    public async void dial( string number, string type ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void activate() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void hangup_active() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void hangup_all() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void hold_all_active() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void release( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void release_all_held() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void release_all_active() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void create_conference() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void transfer() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void deflect( string number ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void join() throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }


    public async void cancel_outgoing_with_id( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }

    public async void reject_incoming_with_id( int id ) throws FreeSmartphone.GSM.Error, FreeSmartphone.Error
    {
    }
}

// vim:ts=4:sw=4:expandtab
