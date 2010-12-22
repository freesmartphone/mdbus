#!/usr/bin/env python
"""
org.freesmartphone.Usage unit tests

(C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
GPLv2 or later
"""

import gobject
import thread
import time
import dbus
import dbus.service
import unittest
import sys
import dbus.mainloop.glib

ORG_FREESMARTPHONE_RESOURCE = "org.freesmartphone.Resource"
ORG_FREESMARTPHONE_UNITTEST = "org.freesmartphone.Testing"

TEST_RESOURCE_NAME = "UnitTestResource"
TEST_RESOURCE_PATH = "/org/freesmartphone/Testing"

#=========================================================================#
class ResourceTest( unittest.TestCase ):
#=========================================================================#
    """Tests for org.freesmartphone.Usage.*"""

    def setUp( self ):
        #
        # FIXME: Check whether the dbus system.conf is allowing arbitrary
        # method calls, otherwise these tests will fail with AccessDenied
        self.bus = dbus.SystemBus()
        obj = self.bus.get_object( "org.freesmartphone.ousaged", "/org/freesmartphone/Usage" )
        self.usage = dbus.Interface( obj, "org.freesmartphone.Usage" )

        obj = self.bus.get_object( "org.freesmartphone.testing", "/org/freesmartphone/Testing" )
        self.testresource = dbus.Interface( obj, "org.freesmartphone.Testing" )

    def tearDown( self ):
        pass

    def test_000( self ):
        """org.freesmartphone.Usage.ListResource"""
        try:
            self.testresource.Unregister()
            time.sleep( 1 )
        except dbus.DBusException, e:
            pass
        resources = self.usage.ListResources()
        assert ( resources == [] )
        self.testresource.Register()
        time.sleep( 1 )
        resources = self.usage.ListResources()
        assert ( resources == [ TEST_RESOURCE_NAME ] )
        assert ( self.testresource.ResourceState() == "disabled" )

    def test_002( self ):
        """org.freesmartphone.Usage.GetResourceState"""
        state = self.usage.GetResourceState( TEST_RESOURCE_NAME )
        assert ( not state )

    def test_003( self ):
        """org.freesmartphone.Usage.RequestResource"""
        self.usage.RequestResource( TEST_RESOURCE_NAME )
        state = self.usage.GetResourceState( TEST_RESOURCE_NAME )
        assert ( state )
        assert ( self.testresource.ResourceState() == "enabled" )

    def test_004( self ):
        """org.freesmartphone.Usage.ReleaseResource"""
        self.usage.ReleaseResource( TEST_RESOURCE_NAME )
        state = self.usage.GetResourceState( TEST_RESOURCE_NAME )
        assert ( not state )
        assert ( self.testresource.ResourceState() == "disabled" )

    def test_005( self ):
        """org.freesmartphone.Usage.SetResourcePolicy (enabled)"""
        self.usage.SetResourcePolicy( TEST_RESOURCE_NAME, "enabled" )
        state = self.usage.GetResourceState( TEST_RESOURCE_NAME )
        assert ( state )
        assert ( self.testresource.ResourceState() == "enabled" )

    def test_006( self ):
        """org.freesmartphone.Usage.SetResourcePolicy (disabled)"""
        self.usage.SetResourcePolicy( TEST_RESOURCE_NAME, "disabled" )
        state = self.usage.GetResourceState( TEST_RESOURCE_NAME )
        assert ( not state )
        assert ( self.testresource.ResourceState() == "disabled" )

#=========================================================================#
if __name__ == "__main__":
#=========================================================================#
    suites = []
    suites.append( unittest.defaultTestLoader.loadTestsFromTestCase( ResourceTest ) )
    # FIXME this is not conform with unit tests, but for now we only test this file anyways
    # will fix later
    for suite in suites:
        result = unittest.TextTestRunner( verbosity=3 ).run( suite )

