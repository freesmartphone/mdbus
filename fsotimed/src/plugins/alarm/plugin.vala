/*
 * Alarm plugin for otimed
 *
 * (C) 2009 Sudharshan "Sup3rkiddo" S <sudharsh@gmail.com>
 * (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using GLib;
using Gee;
using DBus;
using FreeSmartphone;

internal const int COMPENSATE_SECONDS = 5;

public class AlarmController : FreeSmartphone.Time.Alarm, FsoFramework.AbstractObject
{
    private FsoFramework.DBusSubsystem subsystem;
    private dynamic DBus.Object rtc;
    private HashMap<string,int> alarms;
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

        alarms = new HashMap<string,int>( str_hash, str_equal );
    }

    public override string repr()
    {
        return "<%s>".printf( FsoFramework.Time.AlarmServicePath );
    }

    private bool schedule()
    {
        logger.debug( "Rescheduling wakeup alarms" );

        var now = TimeVal();
        var missed = new ArrayList<string>();

        // compute all that have hit since last schedule
        foreach ( var busname in alarms.keys )
        {
            if ( alarms[busname] < (int)now.tv_sec + COMPENSATE_SECONDS )
            {
                missed.add( busname );
            }
        }

        // ping and remove them
        foreach ( var busname in missed )
        {
            logger.info( "Notifying %s about its alarm on %d".printf( busname, alarms[busname] ) );
            alarmNotificationViaDbus( busname );
            alarms.remove( busname );
        }

        if ( alarms.size == 0 )
        {
            logger.info( "No more alarms. Clearing all timers." );
            if ( timer != 0 )
            {
                Source.remove( timer );
            }
            setRtcWakeupTime( 0 );
            return false;
        }

        // program the newest one into mainloop & RTC
        int next = 1952801220;
        var name = "";
        foreach ( var busname in alarms.keys )
        {
            if ( alarms[busname] < next )
            {
                next = alarms[busname];
                name = busname;
            }
        }
        now.get_current_time();
        int seconds = next - (int)now.tv_sec;
        logger.info( "Programming mainloop & rtc alarm for %s at %d (%d seconds from now)".printf( name, next, seconds ) );

        // program mainloop timer
        if ( timer != 0 )
        {
            Source.remove( timer );
        }
        timer = Timeout.add_seconds( seconds, schedule );

        setRtcWakeupTime( next );

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
            logger.error( "Can't program RTC wakeup time: %s".printf( e.message ) );
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
            logger.error( "%s. Can't notify client".printf( e.message ) );
        }
        else
        {
            logger.info( "Alarm Notification OK" );
        }
    }

    //
    // DBUS
    //
    public void clear_alarm( string busname ) throws DBus.Error
    {
        if ( busname in alarms )
        {
            alarms.remove( busname );
            schedule();
        }
    }

    public void set_alarm( string busname, int timestamp ) throws FreeSmartphone.Error, DBus.Error
    {
        var now = TimeVal();
        if ( (int)now.tv_sec >= timestamp )
        {
            throw new FreeSmartphone.Error.INVALID_PARAMETER( "Timestamp not in the future." );
        }
        alarms[busname] = timestamp;
        Idle.add( schedule );
    }
}

AlarmController instance;

public static string fso_factory_function( FsoFramework.DBusSubsystem subsystem ) throws DBus.Error
{
    instance = new AlarmController( subsystem );
    return "fsotime.alarm";
}


[ModuleInit]
public static void fso_register_function( TypeModule module )
{
    debug( "fsotimed.alarm fso_register_function()" );
}

