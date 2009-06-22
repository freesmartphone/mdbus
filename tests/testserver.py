#!/usr/bin/env python
"""
unit tests dbus test server

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

#===========================================================================#
class ClientResource( dbus.service.Object ):
#===========================================================================#
    def __init__( self ):
        self.newState( "unknown" )
        self.bus = dbus.SystemBus()
        dbus.service.Object.__init__( self, self.bus, TEST_RESOURCE_PATH )
        obj = self.bus.get_object( "org.freesmartphone.ousaged", "/org/freesmartphone/Usage" )
        self.usage = dbus.Interface( obj, "org.freesmartphone.Usage" )
        self.busname = dbus.service.BusName( "org.freesmartphone.testing", self.bus )

    def newState( self, state ):
        self.state = state
        print "state now %s" % self.state

    def ok( self, *args ):
        print "dbus reply ok"
        print "state now %s" % self.state

    def error( self, *args ):
        print "dbus reply error: %s" % (args)
        print "state now %s" % self.state

    #
    # org.freesmartphone.Resource
    #

    @dbus.service.method( ORG_FREESMARTPHONE_RESOURCE, "", "" )
    def Enable( self ):
        assert ( self.state != "enabled" )
        self.newState( "enabled" )

    @dbus.service.method( ORG_FREESMARTPHONE_RESOURCE, "", "" )
    def Disable( self ):
        #assert ( self.state != "disabled" )
        self.newState( "disabled" )

    @dbus.service.method( ORG_FREESMARTPHONE_RESOURCE, "", "" )
    def Suspend( self ):
        assert ( self.state == "enabled" )
        self.newState( "suspended" )

    @dbus.service.method( ORG_FREESMARTPHONE_RESOURCE, "", "" )
    def Resume( self ):
        assert ( self.state == "suspended" )
        self.newState( "enabled" )

    #
    # org.freesmartphone.UnitTest
    #
    @dbus.service.method( ORG_FREESMARTPHONE_UNITTEST, "", "" )
    def Register( self ):
        self.newState( "unknown" )
        self.usage.RegisterResource( TEST_RESOURCE_NAME, TEST_RESOURCE_PATH, reply_handler=self.ok, error_handler=self.error )

    @dbus.service.method( ORG_FREESMARTPHONE_UNITTEST, "", "" )
    def Unregister( self ):
        self.usage.UnregisterResource( TEST_RESOURCE_NAME, reply_handler=self.ok, error_handler=self.error )

    @dbus.service.method( ORG_FREESMARTPHONE_UNITTEST, "", "s" )
    def ResourceState( self ):
        return self.state

#=========================================================================#
if __name__ == "__main__":
#=========================================================================#
    loop = gobject.MainLoop()
    dbus.mainloop.glib.DBusGMainLoop( set_as_default=True )
    server = ClientResource()
    loop.run()

