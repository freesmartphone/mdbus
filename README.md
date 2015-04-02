MDBUS2 1 "MARCH 2015" Linux "User Manuals"
==========================================

NAME
----

mdbus2 - Interactive DBus introspection, interaction, and monitoring

SYNOPSIS
--------

`mdbus2` [`OPTIONS...`] [ `servicename` [ `objectpath` [ `method` [ `params...` ] ] ] ]

`mdbus2 -si`

`mdbus2 -sl`

DESCRIPTION
-----------

The `mdbus2` command is used to explore and interact with DBus
services on your *system bus* and *session bus*. The system-wide message bus
exists only once and is installed on many systems as the "messagebus" service.
The session message bus is per-user-login (started each time a user logs in)
and usually tied to your X11 session.

In the simplest form, mdbus2 shows the available services on the
selected bus. Given a *service name*, it will show the available
*objects* exported by the service. Given a service name and an
*object path*, it will show the exposed *methods*, *signals*, and
*properties* of that object.

Supplying a *method name* (and *parameters*), you can call methods on the object and get the return value(s).

In the *listening mode*, you can observe signals sent on the selected bus.

Also included is an *interactive shell* with tab-completion and command history.

OPTIONS
-------

`--show-anonymous`, `-a`
  Also show *unique* (anonymous) services on the bus.    

`--system`, `-s`
  Use the system bus instead of the (default) session bus.

`-show-pids`, `-p`
  Show UNIX process IDs.

`--listen`, `-l`
  Start the listener mode, in which you can observe signals on the bus.

`--interactive`, `-i`
  Start an interactive shell.
  
`--annotate-types`, `-t`
  Annotate DBus types.

EXAMPLES
-----------
Find out which bus names are currently registered on the system bus:

	root@om-gta02:~# mdbus -s
	:1.0
	:1.1
	:1.2
	:1.42
	:1.47
	:1.60
	:1.61
	org.bluez
	org.freedesktop.Avahi
	org.freedesktop.DBus
	org.freesmartphone.frameworkd
	org.freesmartphone.ogsmd
	org.pyneo.muxer

Find out which objects are served by a certain service:

	root@om-gta02:~# mdbus -s org.freesmartphone.frameworkd
	/
	/org
	/org/freesmartphone
	/org/freesmartphone/Framework
	/org/freesmartphone/GSM
	/org/freesmartphone/GSM/Device
	/org/freesmartphone/GSM/Server
	
Find out the interface of a certain object:

	root@om-gta02:~# mdbus -s org.freesmartphone.ogsmd /org/freesmartphone/GSM/Device
	[METHOD]    org.freesmartphone.GSM.Call.Activate( i:index )
	[METHOD]    org.freesmartphone.GSM.Call.ActivateConference( i:index )
	[METHOD]    org.freesmartphone.GSM.Call.HoldActive()
	[METHOD]    org.freesmartphone.GSM.Call.Initiate( s:number, s:type_ )
	[METHOD]    org.freesmartphone.GSM.Call.Release( i:index )
	[METHOD]    org.freesmartphone.GSM.Call.ReleaseAll()
	[METHOD]    org.freesmartphone.GSM.Call.ReleaseHeld()
	[SIGNAL]    org.freesmartphone.GSM.Call.CallStatus( i:index, s:status, a{sv}:properties )
	[METHOD]    org.freedesktop.DBus.Introspectable.Introspect()
	[METHOD]    org.freesmartphone.GSM.Device.CancelCommand()
	[METHOD]    org.freesmartphone.GSM.Device.GetAntennaPower()
	[METHOD]    org.freesmartphone.GSM.Device.GetFeatures()
	[METHOD]    org.freesmartphone.GSM.Device.GetInfo()
	[METHOD]    org.freesmartphone.GSM.Device.PrepareForSuspend()
	[METHOD]    org.freesmartphone.GSM.Device.RecoverFromSuspend()
	[METHOD]    org.freesmartphone.GSM.Device.SetAntennaPower( b:power )
	[METHOD]    org.freesmartphone.GSM.SIM.ChangeAuthCode( s:old_pin, s:new_pin )
	[METHOD]    org.freesmartphone.GSM.SIM.DeleteEntry( i:index )
	[METHOD]    org.freesmartphone.GSM.SIM.DeleteMessage( i:index )
	[METHOD]    org.freesmartphone.GSM.SIM.GetAuthStatus()
	[METHOD]    org.freesmartphone.GSM.SIM.GetImsi()
	[METHOD]    org.freesmartphone.GSM.SIM.GetMessagebookInfo()
	[METHOD]    org.freesmartphone.GSM.SIM.GetPhonebookInfo()
	[METHOD]    org.freesmartphone.GSM.SIM.GetServiceCenterNumber()
	[METHOD]    org.freesmartphone.GSM.SIM.GetSimCountryCode()
	[METHOD]    org.freesmartphone.GSM.SIM.GetSubscriberNumbers()
	[METHOD]    org.freesmartphone.GSM.SIM.RetrieveEntry( i:index )
	[METHOD]    org.freesmartphone.GSM.SIM.RetrieveMessage( i:index )
	[METHOD]    org.freesmartphone.GSM.SIM.RetrieveMessagebook( s:category )
	[METHOD]    org.freesmartphone.GSM.SIM.RetrievePhonebook()
	[METHOD]    org.freesmartphone.GSM.SIM.SendAuthCode( s:code )
	[METHOD]    org.freesmartphone.GSM.SIM.SetServiceCenterNumber( s:number )
	[METHOD]    org.freesmartphone.GSM.SIM.StoreEntry( i:index, s:name, s:number )
	[METHOD]    org.freesmartphone.GSM.SIM.StoreMessage( s:number, s:contents )
	[METHOD]    org.freesmartphone.GSM.SIM.Unlock( s:puk, s:new_pin )
	[SIGNAL]    org.freesmartphone.GSM.SIM.AuthStatus( s:status )
	[SIGNAL]    org.freesmartphone.GSM.SIM.NewMessage( i:index )
	[METHOD]    org.freesmartphone.GSM.Network.DisableCallForwarding( s:reason, s:class_ )
	[METHOD]    org.freesmartphone.GSM.Network.EnableCallForwarding( s:reason, s:class_, s:number, i:timeout )
	[METHOD]    org.freesmartphone.GSM.Network.GetCallForwarding( s:reason )
	[METHOD]    org.freesmartphone.GSM.Network.GetCallingIdentification()
	[METHOD]    org.freesmartphone.GSM.Network.GetNetworkCountryCode()
	[METHOD]    org.freesmartphone.GSM.Network.GetSignalStrength()
	[METHOD]    org.freesmartphone.GSM.Network.GetStatus()
	[METHOD]    org.freesmartphone.GSM.Network.ListProviders()
	[METHOD]    org.freesmartphone.GSM.Network.Register()
	[METHOD]    org.freesmartphone.GSM.Network.RegisterWithProvider( i:operator_code )
	[METHOD]    org.freesmartphone.GSM.Network.SetCallingIdentification( s:status )
	[METHOD]    org.freesmartphone.GSM.Network.Unregister()
	[SIGNAL]    org.freesmartphone.GSM.Network.SignalStrength( i:strength )
	[SIGNAL]    org.freesmartphone.GSM.Network.Status( a{sv}:status )
	[METHOD]    org.freesmartphone.GSM.PDP.ActivateContext( s:apn, s:user, s:password )
	[METHOD]    org.freesmartphone.GSM.PDP.DeactivateContext()
	[METHOD]    org.freesmartphone.GSM.PDP.GetCurrentGprsClass()
	[METHOD]    org.freesmartphone.GSM.PDP.ListAvailableGprsClasses()
	[METHOD]    org.freesmartphone.GSM.PDP.SetCurrentGprsClass( s:class_ )
	[SIGNAL]    org.freesmartphone.GSM.PDP.ContextStatus( i:index, s:status, a{sv}:properties )
	[METHOD]    org.freesmartphone.GSM.Test.Command( s:command )
	[METHOD]    org.freesmartphone.GSM.Test.Echo( s:echo )

Call a method on an interface:

	root@om-gta02 ~ $ mdbus -s org.freesmartphone.ogsmd /org/freesmartphone/GSM/Device org.freesmartphone.GSM.Device.GetInfo
	{   'imei': '354651011234567',
	    'manufacturer': 'FIC/OpenMoko',
	    'model': '"Neo1973 GTA02 Embedded GSM Modem"',
	    'revision': '"HW: GTA02BV5, GSM: gsm_ac_gp_fd_pu_em_cph_ds_vc_cal35_ri_36_amd8_ts0-Moko8"'}

Use it in listening mode:

	root@om-gta02:/local/pkg/fso/framework/framework# mdbus -s -l
	listening for signals on SystemBus from service 'all', object 'all'...
	 [SIGNAL]    org.freedesktop.DBus.NameOwnerChanged    from org.freedesktop.DBus /org/freedesktop/DBus
	(dbus.String(u'org.pyneo.muxer'), dbus.String(u':1.6'), dbus.String(u''))
	 [SIGNAL]    org.freedesktop.DBus.NameOwnerChanged    from org.freedesktop.DBus /org/freedesktop/DBus
	(dbus.String(u':1.6'), dbus.String(u':1.6'), dbus.String(u''))
	 [SIGNAL]    org.freedesktop.DBus.NameOwnerChanged    from org.freedesktop.DBus /org/freedesktop/DBus
	(dbus.String(u':1.28'), dbus.String(u''), dbus.String(u':1.28'))
	 [SIGNAL]    org.freedesktop.DBus.NameOwnerChanged    from org.freedesktop.DBus /org/freedesktop/DBus
	(dbus.String(u'org.freesmartphone.frameworkd'), dbus.String(u''), dbus.String(u':1.28'))
	 [SIGNAL]    org.freedesktop.DBus.NameOwnerChanged    from org.freedesktop.DBus /org/freedesktop/DBus
	(dbus.String(u'org.freesmartphone.ogsmd'), dbus.String(u''), dbus.String(u':1.28'))
	 [SIGNAL]    org.freedesktop.DBus.NameOwnerChanged    from org.freedesktop.DBus /org/freedesktop/DBus
	(dbus.String(u':1.29'), dbus.String(u''), dbus.String(u':1.29'))
	 [SIGNAL]    org.freedesktop.DBus.NameOwnerChanged    from org.freedesktop.DBus /org/freedesktop/DBus
	(dbus.String(u'org.pyneo.muxer'), dbus.String(u''), dbus.String(u':1.29'))
	 [SIGNAL]    org.freedesktop.DBus.NameOwnerChanged    from org.freedesktop.DBus /org/freedesktop/DBus
	(dbus.String(u':1.30'), dbus.String(u''), dbus.String(u':1.30'))
	 [SIGNAL]    org.freesmartphone.GSM.SIM.ReadyStatus    from :1.28 /org/freesmartphone/GSM/Device
	(dbus.Boolean(False),)
	 [SIGNAL]    org.freesmartphone.GSM.SIM.AuthStatus    from :1.28 /org/freesmartphone/GSM/Device
	(dbus.String(u'SIM PIN'),)
	 [SIGNAL]    org.freesmartphone.GSM.SIM.AuthStatus    from :1.28 /org/freesmartphone/GSM/Device
	(dbus.String(u'READY'),)
	 [SIGNAL]    org.freesmartphone.GSM.SIM.ReadyStatus    from :1.28 /org/freesmartphone/GSM/Device
	(dbus.Boolean(True),)


BUGS
----

Please send bug reports to fso@openphoenux.org or use our issue tracker at [the project page](https://github.com/freesmartphone/mdbus/issues).

NOTES
-----

* mdbus2 requires *well-behaved DBus services*, this means, services that adhere to the DBus introspection protocol.
* Your message bus configuration may keep mdbus2 from seeing all messages, especially if you run it as a non-root user.

AUTHOR
------

Michael 'Mickey' Lauer <mickey@vanille.de>

SEE ALSO
--------

dbus-send(1), dbus-monitor(1), gdbus(1), qdbus(1), [DBus Homepage](http://www.freedesktop.org/dbus)
