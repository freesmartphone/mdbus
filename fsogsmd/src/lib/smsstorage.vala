/*
 * Copyright (C) 2009-2011 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

using Gee;

namespace FsoGsm
{
    public const string SMS_STORAGE_DEFAULT_STORAGE_DIR = "/tmp/fsogsmd/sms";
    public const string SMS_STORAGE_SENT_UNCONFIRMED = "sent-unconfirmed";
    public const int SMS_STORAGE_DIRECTORY_PERMISSIONS = (int) Posix.S_IRUSR | Posix.S_IWUSR |
                                                               Posix.S_IXUSR | Posix.S_IRGRP |
                                                               Posix.S_IXGRP | Posix.S_IROTH |
                                                               Posix.S_IXOTH;

    public interface ISmsStorage : FsoFramework.AbstractObject
    {
        public abstract void clean();
        public abstract int addSms( Sms.Message message );
        public abstract Gee.ArrayList<string> keys();
        public abstract FreeSmartphone.GSM.SIMMessage message( string key, int index = 0 );
        public abstract FreeSmartphone.GSM.SIMMessage[] messagebook();
        public abstract uint16 lastReferenceNumber();
        public abstract uint16 increasingReferenceNumber();
        public abstract void storeTransactionIndizesForSentMessage( Gee.ArrayList<WrapHexPdu> hexpdus );
        public abstract int confirmReceivedMessage( int netreference );
    }

    public class SmsStorageFactory
    {
        /**
         * Create a new SMS storage for a given IMSI.
         **/
        public static ISmsStorage create( string type, string imsi )
        {
            ISmsStorage storage = null;

            switch ( type )
            {
                case "default":
                    storage = new SmsStorage( imsi );
                    break;
                default:
                    storage = new NullSmsStorage();
                    break;
            }

            return storage;
        }
    }

    /**
     * @class NullSmsStorage
     *
     * A sms storage without a implement for times where no real sms storage handling is
     * needed but required by the implementation (e.g. testing, dummy implementation, ...)
     **/
    public class NullSmsStorage : FsoFramework.AbstractObject, ISmsStorage
    {
        public void clean()
        {
        }

        public int addSms( Sms.Message message )
        {
            return 1;
        }

        public Gee.ArrayList<string> keys()
        {
            return new Gee.ArrayList<string>();
        }

        public FreeSmartphone.GSM.SIMMessage message( string key, int index = 0 )
        {
            return FreeSmartphone.GSM.SIMMessage( index, "unknown", "1234567890", "0",
                "Test", new GLib.HashTable<string,GLib.Variant>( null, null ) );
        }

        public FreeSmartphone.GSM.SIMMessage[] messagebook()
        {
            return new FreeSmartphone.GSM.SIMMessage[] { };
        }

        public uint16 lastReferenceNumber()
        {
            return 0;
        }

        public uint16 increasingReferenceNumber()
        {
            return 0;
        }

        public void storeTransactionIndizesForSentMessage( Gee.ArrayList<WrapHexPdu> hexpdus )
        {
        }

        public int confirmReceivedMessage( int netreference )
        {
            return 0;
        }

        public override string repr()
        {
            return @"<>";
        }
    }

    /**
     * @class SmsStorage
     *
     * A high level persistent SMS Storage abstraction.
     */
    public class SmsStorage : FsoFramework.AbstractObject, ISmsStorage
    {
        private static string storagedirprefix;
        private string imsi;
        private string storagedir;

        static construct
        {
            storagedirprefix = SMS_STORAGE_DEFAULT_STORAGE_DIR;
        }

        // for debugging purposes mainly
        public static void setStorageDir( string dirname )
        {
            storagedirprefix = dirname;
        }

        public override string repr()
        {
            return imsi != null ? @"<$imsi>" : @"<>";
        }

        //
        // public API
        //

        public SmsStorage( string imsi )
        {
            this.imsi = imsi;
            storagedirprefix = config.stringValue( CONFIG_SECTION, "sms_storage_dir", SMS_STORAGE_DEFAULT_STORAGE_DIR );
            this.storagedir = GLib.Path.build_filename( storagedirprefix, imsi );
            GLib.DirUtils.create_with_parents( storagedir, SMS_STORAGE_DIRECTORY_PERMISSIONS );
            logger.info( @"Created w/ storage dir $(this.storagedir)" );
        }

        public const int SMS_ALREADY_SEEN = -1;
        public const int SMS_MULTI_INCOMPLETE = 0;
        public const int SMS_SINGLE_COMPLETE = 1;

        public void clean()
        {
            FsoFramework.FileHandling.removeTree( this.storagedir );
        }

        /**
         * Hand a new message over to the storage.
         *
         * @note The storage will now own the message.
         * @returns -1, if the message is already known.
         * @returns 0, if the message is a fragment of an incomplete concatenated sms.
         * @returns 1, if the message is not concatenated, hence complete.
         * @returns n > 1, if the message is a fragment which completes an incomplete concatenated sms composed out of n fragments.
         **/
        public int addSms( Sms.Message message )
        {
            // only deal with DELIVER types for now
            if ( message.type != Sms.Type.DELIVER )
            {
                logger.info( "Ignoring message with type %u (!= DELIVER)".printf( (uint)message.type ) );
                return SMS_ALREADY_SEEN;
            }
            // generate hash
            var smshash = message.hash();

            uint16 ref_num;
            uint8 max_msgs = 1;
            uint8 seq_num = 1;

            GLib.DirUtils.create_with_parents( GLib.Path.build_filename( storagedir, smshash ), SMS_STORAGE_DIRECTORY_PERMISSIONS );

            if ( !message.extract_concatenation( out ref_num, out max_msgs, out seq_num ) )
            {
                // message is not concatenated
                var filename = GLib.Path.build_filename( storagedir, smshash, "001" );
                if ( FsoFramework.FileHandling.isPresent( filename ) )
                {
                    return SMS_ALREADY_SEEN;
                }
                // message is not present, save it
                FsoFramework.FileHandling.writeBuffer( message, message.size(), filename, true );
                return SMS_SINGLE_COMPLETE;
            }
            else
            {
                // message is concatenated
                var filename = GLib.Path.build_filename( storagedir, smshash, "%03u".printf( seq_num ) );
                if ( FsoFramework.FileHandling.isPresent( filename ) )
                {
                    return SMS_ALREADY_SEEN;
                }
    #if DEBUG
                GLib.message( "fragment file %s now present, checking for completeness...", filename );
    #endif
                // message is not present, save it
                FsoFramework.FileHandling.writeBuffer( message, message.size(), filename, true );
                // check whether we have all fragments?
                for( int i = 1; i <= max_msgs; ++i )
                {
                    var fragmentfilename = GLib.Path.build_filename( storagedir, smshash, "%03u".printf( i ) );
                    if( !FsoFramework.FileHandling.isPresent( fragmentfilename ) )
                    {
    #if DEBUG
                        GLib.message( "fragment file %s not present ==> INCOMPLETE", fragmentfilename );
    #endif
                        return SMS_MULTI_INCOMPLETE;
                    }
    #if DEBUG
                    GLib.message( "fragment file %s present", fragmentfilename );
    #endif
                }
                return max_msgs; // SMS_MULTI_COMPLETE
            }
        }

        public Gee.ArrayList<string> keys()
        {
            var result = new Gee.ArrayList<string>();
            GLib.Dir dir;
            try
            {
                dir = GLib.Dir.open( storagedir );
                for ( var smshash = dir.read_name(); smshash != null; smshash = dir.read_name() )
                {
                    result.add( smshash );
                }
            }
            catch ( GLib.Error e )
            {
                logger.error( @"Can't access SMS storage dir: $(e.message)" );
            }
            return result;
        }

        public FreeSmartphone.GSM.SIMMessage message( string key, int index = 0 )
        {
            var result = FreeSmartphone.GSM.SIMMessage(
                index,
                "unknown",
                "unknown",
                "unknown",
                "unknown",
                new GLib.HashTable<string,Variant>( str_hash, str_equal )
            );

            if ( ! ( key in keys() ) )
            {
                return result;
            }

            if ( key.has_suffix( "_1" ) )
            {
                // single SMS
                string contents;
                try
                {
                    GLib.FileUtils.get_contents( GLib.Path.build_filename( storagedir, key, "001" ), out contents );
                }
                catch ( GLib.Error e )
                {
                    logger.error( @"Can't access SMS storage dir: $(e.message)" );
                    return result;
                }
                unowned Sms.Message message = (Sms.Message) contents;

                result.status = "single";
                result.number = message.number();
                result.contents = message.to_string();
                result.timestamp = message.timestamp().to_string();
                result.properties = message.properties();
            }
            else
            {
                // concatenated SMS
                result.status = "concatenated";
                var namecomponents = key.split( "_" );
                var max_fragment = int.parse( namecomponents[namecomponents.length-1] );
    #if DEBUG
                GLib.message( "highest fragment = %d", max_fragment );
    #endif
                var smses = new Sms.Message[max_fragment-1] {};
                bool complete = true;
                bool info = false;

                for( int i = 1; i <= max_fragment; ++i )
                {
                    smses[i-1] = new Sms.Message();
                    var filename = GLib.Path.build_filename( storagedir, key, "%03u".printf( i ) );
                    if ( ! FsoFramework.FileHandling.isPresent( filename ) )
                    {
                        complete = false;
                        result.status = "incomplete";

                        smses[i-1] = null;
                    }
                    else
                    {
                        string contents;
                        try
                        {
                            GLib.FileUtils.get_contents( filename, out contents );
                        }
                        catch ( GLib.Error e )
                        {
                            logger.error( @"Can't access SMS storage dir: $(e.message)" );
                            return result;
                        }
                        Memory.copy( smses[i-1], contents, Sms.Message.size() );

                        if ( !info )
                        {
                            result.number = smses[i-1].number();
                            result.timestamp = smses[i-1].timestamp().to_string();
                            result.properties = smses[i-1].properties();
                            info = true;
                        }
                    }
                }

                var smslist = new SList<weak Sms.Message>();
                for( int i = 0; i < max_fragment; ++i )
                {
                    if ( smses[i] != null )
                    {
                            smslist.append( smses[i] );
                    }
                }
                var text = Sms.decode_text( smslist );
                result.contents = ( text != null ) ? text : "decode error";
            }
            return result;
        }

        public FreeSmartphone.GSM.SIMMessage[] messagebook()
        {
            var mb = new FreeSmartphone.GSM.SIMMessage[] {};
            var index = 0;
            foreach ( var key in keys() )
            {
                mb += message( key, index = index++ );
            }
            return mb;
        }

        public uint16 lastReferenceNumber()
        {
            var filename = GLib.Path.build_filename( storagedir, "refnum" );
            return (uint16) int.parse( FsoFramework.FileHandling.readIfPresent( filename ) );
        }

        public uint16 increasingReferenceNumber()
        {
            var filename = GLib.Path.build_filename( storagedir, "refnum" );
            var number = FsoFramework.FileHandling.readIfPresent( filename );
            uint16 num = (uint16) int.parse( number ) + 1;
            FsoFramework.FileHandling.write( num.to_string(), filename, true ); // create, if not existing
            return num;
        }

        public void storeTransactionIndizesForSentMessage( Gee.ArrayList<WrapHexPdu> hexpdus )
        {
            var refnum = lastReferenceNumber().to_string();

            var name = "";
            foreach ( var hexpdu in hexpdus )
            {
                name += @":$(hexpdu.transaction_index)";
            }

            var dirname = GLib.Path.build_filename( storagedir, SMS_STORAGE_SENT_UNCONFIRMED, name );
            if ( ! FsoFramework.FileHandling.isPresent( dirname ) )
            {
                GLib.DirUtils.create_with_parents( dirname, SMS_STORAGE_DIRECTORY_PERMISSIONS );
            }
            foreach ( var hexpdu in hexpdus )
            {
                var filename = GLib.Path.build_filename( dirname, hexpdu.transaction_index.to_string() );
                FsoFramework.FileHandling.write( refnum, filename, true );
            }
        }

        public int confirmReceivedMessage( int netreference )
        {
            var dirname = GLib.Path.build_filename( storagedir, SMS_STORAGE_SENT_UNCONFIRMED );
            var listUnconfirmed = FsoFramework.FileHandling.listDirectory( dirname );
            foreach ( var unconfirmed in listUnconfirmed )
            {
                var components = unconfirmed.split( ":" );
                foreach ( var component in components )
                {
                    if ( int.parse( component ) == netreference )
                    {
    #if DEBUG
                        debug( @"Found reference ($netreference) of unconfirmed SMS:$component in $unconfirmed" );
    #endif
                        var filedirname = GLib.Path.build_filename( dirname, unconfirmed );
                        var filename = GLib.Path.build_filename( filedirname, component );
                        var transaction_index = int.parse( FsoFramework.FileHandling.read( filename ) );
                        GLib.FileUtils.unlink( filename );
                        var ok = GLib.DirUtils.remove( filedirname );
                        if ( ok != 0 )
                        {
    #if DEBUG
                            debug( @"$(strerror(errno)) (Not all fragments confirmed yet)" );
    #endif
                            return -1;
                        }
                        else
                        {
    #if DEBUG
                            debug( @"All fragments confirmed & removed directory. Returning index $transaction_index" );
    #endif
                            return transaction_index;
                        }
                    }
                }
            }
            logger.warning( @"Did not find unconfirmed SMS for reference $netreference" );
            return -1;
        }
    }
}

// vim:ts=4:sw=4:expandtab
