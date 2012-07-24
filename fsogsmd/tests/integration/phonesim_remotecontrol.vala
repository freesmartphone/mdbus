/*
 * (C) 2011-2012 Simon Busch <morphis@gravedo.de>
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 */

[DBus (name = "org.ofono.phonesim.Error")]
public errordomain PhonesimError
{
    [DBus (name = "FileNotFound")]
    FILE_NOT_FOUND,
    [DBus (name = "ScriptExecError")]
    SCRIPT_EXEC_ERROR,
}

[DBus (name = "org.ofono.phonesim.Script", timeout = 120000)]
public interface IPhonesimService : GLib.Object
{
    [DBus (name = "SetPath")]
    public abstract async void set_path( string path ) throws GLib.IOError, GLib.DBusError, PhonesimError;
    [DBus (name = "GetPath")]
    public abstract async string get_path() throws GLib.IOError, GLib.DBusError, PhonesimError;
    [DBus (name = "Run")]
    public abstract async string run( string name ) throws GLib.IOError, GLib.DBusError, PhonesimError;
}

public class PhonesimRemotePhoneControl : FsoFramework.AbstractObject, IRemotePhoneControl
{
    private IPhonesimService _phonesim;
    private string _script_path;

    //
    // private
    //

    private async void ensure_connection() throws RemotePhoneControlError
    {
        if ( _phonesim != null )
            return;

        try
        {
            _phonesim = yield GLib.Bus.get_proxy<IPhonesimService>( BusType.SESSION, "org.ofono.phonesim", "/" );
            yield _phonesim.set_path( _script_path );
        }
        catch ( GLib.Error error )
        {
            throw new RemotePhoneControlError.FAILED( @"Failed to establish a connection to the phonesim service: $(error.message)" );
        }
    }

    private async void execute_script( string script ) throws RemotePhoneControlError
    {
        string path = "tmp.js";
        FsoFramework.FileHandling.write( script, @"$(_script_path)/$(path)", true );

        yield ensure_connection();

        try
        {
            var result = yield _phonesim.run( path );
        }
        catch ( PhonesimError pe )
        {
            throw new RemotePhoneControlError.FAILED( @"Could not execute script on phonesim side: $(pe.message)" );
        }
        catch ( GLib.Error error )
        {
            throw new RemotePhoneControlError.FAILED( @"Could not excute script on phonesim side" );
        }
    }

    //
    // public API
    //

    public PhonesimRemotePhoneControl()
    {
        _script_path = GLib.DirUtils.make_tmp( "fsogsmd-integration-tests-XXXXXX" );
    }

    public async void initiate_call( string number, bool hide ) throws RemotePhoneControlError
    {
        string script = """tabCall.gbIncomingCall.leCaller.text = "%s"; tabCall.gbIncomingCall.pbIncomingCall.click();"""
            .printf( number );
        yield execute_script( script );
    }

    /*
     * FIXME id doesn't have to match as there are not exchanged between phonesim and
     * fsogsmd but if we keep everything in the right order and don't do crazy things
     * we can assume which id is used in phonesim for a new call easily.
     */
    public async void activate_incoming_call( int id ) throws RemotePhoneControlError
    {
        string script = """tabCall.twCallMgt.selectRow( %i ); tabCall.pbActive.click();""".printf( id );
        yield execute_script( script );
    }

    public async void hangup_incoming_call( int id ) throws RemotePhoneControlError
    {
        string script = """tabCall.twCallMgt.selectRow( %i ); tabCall.pbHangup.click();""".printf( id );
        yield execute_script( script );
    }

    public override string repr()
    {
        return @"<>";
    }
}

// vim:ts=4:sw=4:expandtab
