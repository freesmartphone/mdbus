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

using GLib;
using FsoFramework.Test;

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

    public async FreeSmartphone.UsageResourcePolicy get_default_policy() throws FreeSmartphone.ResourceError, FreeSmartphone.Error, GLib.DBusError, GLib.IOError
    {
        return FreeSmartphone.UsageResourcePolicy.AUTO;
    }
}

public class FsoTest.TestUsage : FsoFramework.Test.TestCase
{
    private FreeSmartphone.Usage usage;
    private DummyResource resource;

    public TestUsage()
    {
        base("FreeSmartphone.Usage");

        add_async_test( "ResourceRegistration",
                        cb => test_resource_registration( cb ),
                        res => test_resource_registration.end( res ) );

        add_async_test( "RequestResource",
                        cb => test_request_resource( cb ),
                        res => test_request_resource.end( res ) );

        add_async_test( "ReleaseResource",
                        cb => test_release_resource( cb ),
                        res => test_release_resource.end( res ) );

        add_async_test( "ResourcePolicy",
                        cb => test_resource_policy( cb ),
                        res => test_resource_policy.end( res ) );

        add_async_test( "ResourceDeregistration",
                        cb => test_resource_unregister( cb ),
                        res => test_resource_unregister.end( res ) );

        try
        {
            usage = Bus.get_proxy_sync<FreeSmartphone.Usage>( BusType.SYSTEM, FsoFramework.Usage.ServiceDBusName,
                FsoFramework.Usage.ServicePathPrefix );
            resource = new DummyResource();
            resource.path = "/org/freesmartphone/Test/Usage";

            var systembus = Bus.get_sync( BusType.SYSTEM );

            Bus.own_name_on_connection( systembus, "org.freesmartphone.otestd", BusNameOwnerFlags.REPLACE );
            systembus.register_object<FreeSmartphone.Resource>( resource.path, resource );
        }
        catch ( GLib.Error err )
        {
            critical( @"Can't register dummy resource on the system bus: $(err.message)" );
        }
    }

    public override void set_up()
    {
    }

    public override void tear_down()
    {
    }

    public async void test_resource_registration() throws GLib.Error
    {
        // FIXME we need to find some way to access the parameters supplied with the signal
        Assert.is_true( wait_for_signal( 200, usage, "resource_available", () => {
            usage.register_resource( "Dummy", new GLib.ObjectPath( resource.path ) );
        } ) );

        var resources = yield usage.list_resources();
        Assert.is_true( "Dummy" in resources );
        Assert.is_false( resource.enabled, "Resource is enabled but should not" );
        Assert.is_false( resource.suspended, "Resource is suspended but should not" );
    }

    public async void test_request_resource() throws GLib.Error
    {
        yield usage.request_resource( "Dummy" );
        Assert.is_true( resource.enabled, @"Resource is not enabled but should" );
        Assert.is_false( resource.suspended, "Resource is suspended but should not" );
    }

    public async void test_release_resource() throws GLib.Error
    {
        yield usage.release_resource( "Dummy" );
        Assert.is_false( resource.enabled );
        Assert.is_false( resource.suspended );
    }

    public async void test_resource_policy() throws GLib.Error
    {
        Assert.is_false( resource.enabled );

        var policy = yield usage.get_resource_policy( "Dummy" );
        Assert.is_true( FreeSmartphone.UsageResourcePolicy.AUTO == policy );

        yield usage.set_resource_policy( "Dummy", FreeSmartphone.UsageResourcePolicy.ENABLED );
        policy = yield usage.get_resource_policy( "Dummy" );
        Assert.is_true( FreeSmartphone.UsageResourcePolicy.ENABLED == policy );
        Assert.is_true( resource.enabled );

        yield usage.set_resource_policy( "Dummy", FreeSmartphone.UsageResourcePolicy.DISABLED );
        policy = yield usage.get_resource_policy( "Dummy" );
        Assert.is_true( FreeSmartphone.UsageResourcePolicy.DISABLED == policy );
        Assert.is_false( resource.enabled );

        yield usage.set_resource_policy( "Dummy", FreeSmartphone.UsageResourcePolicy.AUTO );
        policy = yield usage.get_resource_policy( "Dummy" );
        Assert.is_true( FreeSmartphone.UsageResourcePolicy.AUTO == policy );
        Assert.is_false( resource.enabled );
    }

    public async void test_resource_unregister() throws GLib.Error
    {
        // FIXME we need to find some way to access the parameters supplied with the signal
        Assert.is_true( wait_for_signal( 200, usage, "resource_available", () => {
            usage.unregister_resource( "Dummy" );
        } ) );

        var resources = yield usage.list_resources();
        Assert.is_false( "Dummy" in resources );
        Assert.is_false( resource.enabled );
        Assert.is_false( resource.suspended );
    }
}

public static int main( string[] args )
{
    Test.init( ref args );

    TestSuite root = TestSuite.get_root();
    root.add_suite( new FsoTest.TestUsage().get_suite() );

    Test.run();

    return 0;
}

// vim:ts=4:sw=4:expandtab
