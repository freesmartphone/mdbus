/*
 * Alarm plugin for otimed
 *
 * (C) 2009-2010 Sudharshan "Sup3rkiddo" S <sudharsh@gmail.com>
 * (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *
 */

using Gee;
using DBus;

internal const int COMPENSATE_SECONDS = 5;

public class WakeupAlarm
{
    public string busname;
    public int timestamp;
    public DBus.ObjectPath path;

    public WakeupAlarm( string busname, int timestamp )
    {
        this.busname = busname;
        this.timestamp = timestamp;
    }

    public static int compare( void* a, void* b )
    {
        var wa = a as WakeupAlarm;
        var wb = b as WakeupAlarm;
        if ( wa.timestamp < wb.timestamp ) return -1;
        if ( wa.timestamp > wb.timestamp ) return 1;
        return 0;
    }
}

public class AlarmController : FreeSmartphone.Time.Alarm, FsoFramework.AbstractObject
{
    private FsoFramework.DBusSubsystem subsystem;
    private dynamic DBus.Object rtc;
    private TreeSet<WakeupAlarm> alarms;
    private uint timer;

    public AlarmController( FsoFramework.DBusSubsystem subsystem )
    {
        this.subsystem = subsystem;

        subsystem.registerServiceName( FsoFramework.Time.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Time.ServiceDBusName,
                                        FsoFramework.Time.AlarmServicePath,
                                        this );

        DBus.Connection conn = this.subsystem.dbusConnection();

        rtc = conn.get_object( "org.freesmartphone.odeviced",
                               "/org/freesmartphone/Device/RTC/0",
                               "org.freesmartphone.Device.RealtimeClock" );
        logger.info( "created" );

        alarms = new TreeSet<WakeupAlarm>( WakeupAlarm.compare );
    }

    public override string repr()
    {
        return "<%s>".printf( FsoFramework.Time.AlarmServicePath );
    }

    private bool schedule()
    {
        logger.debug( "Rescheduling wakeup alarms" );

        var now = TimeVal();
        var missed = new ArrayList<WakeupAlarm>();

        // compute all that have hit since last schedule
        foreach ( var alarm in alarms )
        {
            if ( alarm.timestamp < (int)now.tv_sec + COMPENSATE_SECONDS )
            {
                missed.add( alarm );
            }
        }

        // ping and remove them
        foreach ( var alarm in missed )
        {
            logger.info( @"Notifying $(alarm.busname) about an alarm on $(alarm.timestamp)" );
            alarmNotificationViaDbus( alarm.busname );
            alarms.remove( alarm );
        }

        if ( alarms.size == 0 )
        {
            logger.info( "No more alarms. Clearing all timers." );
            if ( timer != 0 )
            {
                Source.remove( timer );
            }
            //setRtcWakeupTime( 0 );
            return false;
        }

        // program the newest one into mainloop & RTC
        var next = alarms.first();
        now.get_current_time();
        int seconds = next.timestamp - (int)now.tv_sec;
        logger.info( @"Programming mainloop & rtc alarm for $(next.busname) at $(next.timestamp) in $seconds seconds from now" );

        // program mainloop timer
        if ( timer != 0 )
        {
            Source.remove( timer );
        }
        timer = Timeout.add_seconds( seconds, schedule );

        setRtcWakeupTime( next.timestamp );

        return false; // mainloop: don't call me again
    }

    private void setRtcWakeupTime( int t )
    {
        try
        {
            rtc.SetWakeupTime( t );
        }
        catch ( DBus.Error e )
        {
            logger.error( @"Can't program RTC wakeup time: $(e.message)" );
        }
    }

    private void alarmNotificationViaDbus( string busname )
    {
        dynamic DBus.Object proxy = subsystem.dbusConnection().get_object(
            busname,
            "/",
            "org.freesmartphone.Notification" );
        // async, so that we don't get stuck by broken clients
        proxy.Alarm( onDBusAlarmNotificationReply );
    }

    private void onDBusAlarmNotificationReply( GLib.Error e )
    {
        if ( e != null )
        {
            logger.error( @"Can't notify client: $(e.message)" );
        }
        else
        {
            logger.info( "Alarm Notification sent and received" );
        }
    }

    private void clearAlarms( string busname )
    {
        var toremove = new ArrayList<WakeupAlarm>();
        foreach ( var alarm in alarms )
        {
            if ( alarm.busname == busname )
            {
                toremove.add( alarm );
            }
        }
        foreach ( var element in toremove )
        {
            alarms.remove( element );
        }
        Idle.add( schedule );
    }

    private void removeAlarm( string busname, int timestamp )
    {
        var toremove = new ArrayList<WakeupAlarm>();
        foreach ( var alarm in alarms )
        {
            if ( alarm.busname == busname && alarm.timestamp == timestamp )
            {
                toremove.add( alarm );
            }
        }
        foreach ( var alarm in toremove )
        {
            alarms.remove( alarm );
        }
        Idle.add( schedule );
    }

    //
    // FreeSmartphone.Time.Alarm (DBUS API)
    //
    public async FreeSmartphone.Time.WakeupAlarm[] list_alarms() throws DBus.Error
    {
        var list = new FreeSmartphone.Time.WakeupAlarm[] {};
        foreach ( var alarm in alarms )
        {
            var element = FreeSmartphone.Time.WakeupAlarm() { busname = alarm.busname, timestamp = alarm.timestamp };
            list += element;
        }
        return list;
    }

    public async void clear_alarms( string busname ) throws DBus.Error
    {
        clearAlarms( busname );
    }

    public async void add_alarm( string busname, int timestamp ) throws FreeSmartphone.Error, DBus.Error
    {
        if ( ! ( FsoFramework.isValidDBusName( busname ) ) )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Invalid DBus name." );
        }
        var now = TimeVal();
        if ( (int)now.tv_sec >= timestamp )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Timestamp not in the future." );
        }
        alarms.add( new WakeupAlarm( busname, timestamp ) );
        Idle.add( schedule );
    }

    public async void remove_alarm( string busname, int timestamp ) throws DBus.Error
    {
        removeAlarm( busname, timestamp );
    }
}

AlarmController instance;

public static string fso_factory_function( FsoFramework.DBusSubsystem subsystem ) throws DBus.Error
{
    instance = new AlarmController( subsystem );
    return "fsotdl.alarm";
}


[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    FsoFramework.theLogger.debug( "fsotdl.alarm fso_register_function()" );
}
