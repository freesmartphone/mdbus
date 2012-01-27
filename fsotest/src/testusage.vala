/*
 * (C) 2011 Simon Busch <morphis@gravedo.de>
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

using GLib;

public class DummyResource : GLib.Object, FreeSmartphone.Resource
{
    public string path { get; set; default = ""; }
    public bool enabled { get; set; default = false; }
    public bool suspended { get; set; default = false; }

    public async void disable() throws FreeSmartphone.ResourceError, GLib.DBusError, GLib.IOError
    {
        enabled = false;
    }

    public async void enable() throws FreeSmartphone.ResourceError, GLib.DBusError, GLib.IOError
    {
        enabled = true;
    }

    public async GLib.HashTable<string,GLib.Variant> get_dependencies() throws FreeSmartphone.ResourceError, GLib.DBusError, GLib.IOError
    {
        return new GLib.HashTable<string,GLib.Variant>( null, null );
    }

    public async void resume() throws FreeSmartphone.ResourceError, GLib.DBusError, GLib.IOError
    {
        suspended = false;
    }

    public async void suspend() throws FreeSmartphone.ResourceError, GLib.DBusError, GLib.IOError
    {
        suspended = false;
    }
}

public class FsoTest.TestUsage : FsoTest.Fixture
{
    private FreeSmartphone.Usage usage;
    private DummyResource resource;

    public TestUsage()
    {
        name = "Usage";

        add_async_test( "/org/freesmartphone/Usage/ResourceRegistration",
                        cb => test_resource_registration( cb ),
                        res => test_resource_registration.end( res ) );

        add_async_test( "/org/freesmartphone/Usage/RequestResource",
                        cb => test_request_resource( cb ),
                        res => test_request_resource.end( res ) );

        add_async_test( "/org/freesmartphone/Usage/ReleaseResource",
                        cb => test_release_resource( cb ),
                        res => test_release_resource.end( res ) );

        add_async_test( "/org/freesmartphone/Usage/ResourceDeregistration",
                        cb => test_resource_unregister( cb ),
                        res => test_resource_unregister.end( res ) );
    }

    public override async void setup()
    {
        try
        {
            usage = Bus.get_proxy_sync<FreeSmartphone.Usage>( BusType.SYSTEM, FsoFramework.Usage.ServiceDBusName,
                FsoFramework.Usage.ServicePathPrefix );
            resource = new DummyResource();
            resource.path = "/org/freesmartphone/Test/Usage";

            var systembus = yield Bus.get( BusType.SYSTEM );

            Bus.own_name_on_connection( systembus, "org.freesmartphone.otestd", BusNameOwnerFlags.REPLACE );
            systembus.register_object<FreeSmartphone.Resource>( resource.path, resource );
        }
        catch ( GLib.Error err )
        {
            critical( @"Can't register dummy resource on the system bus: $(err.message)" );
        }
    }

    public async void test_resource_registration() throws GLib.Error, AssertError
    {
        // FIXME we need to find some way to access the parameters supplied with the signal
        Assert.is_true( wait_for_signal( 200, usage, "resource_available", () => {
            usage.register_resource( "Dummy", new GLib.ObjectPath( resource.path ) );
        } ) );

        var resources = yield usage.list_resources();
        Assert.is_true( "Dummy" in resources );
        Assert.are_equal( false, resource.enabled );
        Assert.are_equal( false, resource.suspended );
    }

    public async void test_request_resource() throws GLib.Error, AssertError
    {
        yield usage.request_resource( "Dummy" );
        Assert.are_equal( true, resource.enabled );
        Assert.are_equal( false, resource.suspended );
    }

    public async void test_release_resource() throws GLib.Error, AssertError
    {
        yield usage.release_resource( "Dummy" );
        Assert.are_equal( false, resource.enabled );
        Assert.are_equal( false, resource.suspended );
    }

    public async void test_resource_unregister() throws GLib.Error, AssertError
    {
        // FIXME we need to find some way to access the parameters supplied with the signal
        Assert.is_true( wait_for_signal( 200, usage, "resource_available", () => {
            usage.unregister_resource( "Dummy" );
        } ) );

        var resources = yield usage.list_resources();
        Assert.is_false( "Dummy" in resources );
        Assert.are_equal( false, resource.enabled );
        Assert.are_equal( false, resource.suspended );
    }

    public override void teardown()
    {
    }
}

// vim:ts=4:sw=4:expandtab
