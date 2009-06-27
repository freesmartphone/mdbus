/* 
 * plugin.vala, Alarm plugin for otimed
 * Written by FSO Team
 * All Rights Reserved
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
using DBus;
using FreeSmartphone;


public class AlarmController : FreeSmartphone.Time.Alarm, FsoFramework.AbstractObject
{

    private FsoFramework.DBusSubsystem subsystem;
    private dynamic DBus.Object rtc;
    private Queue<string> alarm_q = new Queue<string> ();
    private HashTable <string, int> alarm_map = new HashTable<string, int> ((HashFunc)str_hash,
                                                                                  (EqualFunc)str_equal);
    private uint timer_id;

    
    public AlarmController( FsoFramework.DBusSubsystem subsystem )
    {
        this.subsystem = subsystem;
        subsystem.registerServiceName( FsoFramework.Time.ServiceDBusName );
        subsystem.registerServiceObject( FsoFramework.Time.ServiceDBusName,
                                        FsoFramework.Time.AlarmServicePath,
                                        this );

        DBus.Connection conn = this.subsystem.dbusConnection();
        this.rtc = conn.get_object( "org.freesmartphone.odeviced",
                                    "/org/freesmartphone/Device/RealTimeClock/0",
                                    "org.freesmartphone.Device.RealTimeClock" );
        logger.info( "Alarm plugin created" );
        
    }


    private bool schedule()
    {
        TimeVal tv = GLib.TimeVal();
        int now;
        tv.get_current_time();
        now = ( int )tv.tv_sec;

        if ( this.timer_id > 0 )
        {
            Source.remove( this.timer_id );
            this.timer_id = -1;
        }

        while (! this.alarm_q.is_empty() )
        {
            string busname = this.alarm_q.pop_head();
            int alarm = this.alarm_map.lookup( busname );
            if ( alarm < now ) {
                dynamic DBus.Object _proxy = this.subsystem.dbusConnection().get_object( busname, "/", 
                                                                                         "org.freesmartphone.Notification" );
                _proxy.Alarm();
            }
            else {
                tv.get_current_time();
                this.timer_id = GLib.Timeout.add_seconds( alarm - (int)tv.tv_sec, this.schedule );
                this.rtc.SetWakeupTime( alarm );
                break;
            }

        }
        return false;
            
    }
        
    
    public override string repr()
    {
        return "<%s>".printf( FsoFramework.Time.AlarmServicePath );
    }

    
    public void clear_alarm( string busname ) throws DBus.Error
    {
        this.alarm_map.remove( busname );
        this.alarm_q.remove( busname );
        this.schedule();
        logger.info( "Alarm for %s cleared".printf(busname) );                      
    }


    public void set_alarm( string busname, int timestamp ) throws DBus.Error
    {
        this.alarm_map.insert( busname, timestamp );
        this.alarm_q.push_tail( busname );
        this.schedule();
        logger.info( "Alarm set for %s at %d".printf(busname, timestamp) );
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
    debug( "info fso_register_function()" );
}

