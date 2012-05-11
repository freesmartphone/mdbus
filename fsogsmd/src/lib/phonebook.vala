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
    public const string PB_STORAGE_DEFAULT_STORAGE_DIR = "/tmp/fsogsmd/pb";
    public const int PB_STORAGE_DIRECTORY_PERMISSIONS = (int)Posix.S_IRUSR|Posix.S_IWUSR|Posix.S_IXUSR|Posix.S_IRGRP|Posix.S_IXGRP|Posix.S_IROTH|Posix.S_IXOTH;
} /* namespace FsoGsm */

/**
 * @class PhonebookStorage
 *
 * A high level persistent PB Storage abstraction.
 */
public class FsoGsm.PhonebookStorage : FsoFramework.AbstractObject
{
    private static string storagedirprefix;
    private string imsi;
    private string storagedir;

    static construct
    {
        storagedirprefix = PB_STORAGE_DEFAULT_STORAGE_DIR;
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
    public PhonebookStorage( string imsi )
    {
        this.imsi = imsi;
        storagedirprefix = config.stringValue( CONFIG_SECTION, "pb_storage_dir", PB_STORAGE_DEFAULT_STORAGE_DIR );
        this.storagedir = GLib.Path.build_filename( storagedirprefix, imsi );
        GLib.DirUtils.create_with_parents( storagedir, PB_STORAGE_DIRECTORY_PERMISSIONS );
        logger.info( @"Created w/ storage dir $(this.storagedir)" );
    }

    public void clean()
    {
        FsoFramework.FileHandling.removeTree( this.storagedir );
    }

    /*
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
            logger.error( @"Can't access PB storage dir: $(e.message)" );
        }
        return result;
    }
    */

    public void writePhonebookEntry( FreeSmartphone.GSM.SIMEntry entry, string filename )
    {
        var text = @"$(entry.name):$(entry.number)";
        FsoFramework.FileHandling.write( text, filename, true );
    }

    public void addPhonebook( string cat, int mindex, int maxdex, FreeSmartphone.GSM.SIMEntry[] phonebook )
    {
        var pbhash = @"$(cat)_$(mindex)_$(maxdex)";
        var pbdir = GLib.Path.build_filename( storagedir, pbhash );
        GLib.DirUtils.create_with_parents( pbdir, PB_STORAGE_DIRECTORY_PERMISSIONS );

        foreach ( var entry in phonebook )
        {
            var filename = GLib.Path.build_filename( pbdir, "%03u".printf( entry.index ) );
            writePhonebookEntry( entry, filename );
        }
    }

    public FreeSmartphone.GSM.SIMEntry[] phonebook( string cat, int mindex, int maxdex )
    {
        var pb = new FreeSmartphone.GSM.SIMEntry[] {};
        GLib.Dir dir;

        try
        {
            dir = GLib.Dir.open( GLib.Path.build_filename( storagedir ) );
        }
        catch ( GLib.FileError e )
        {
            logger.error( @"Can't open phonebook: $(e.message)" );
            return pb;
        }

        var entry = dir.read_name();
        string pbdirname = null;
        while ( entry != null )
        {
            if ( entry.has_prefix( @"$(cat)_" ) )
            {
                pbdirname = entry;
                break;
            }
            entry = dir.read_name();
        }
        if ( pbdirname != null )
        {
            GLib.Dir pbdir;
            try
            {
                pbdir = GLib.Dir.open( GLib.Path.build_filename( storagedir, pbdirname ) );
            }
            catch ( GLib.FileError e )
            {
                logger.error( @"Can't open phonebook: $(e.message)" );
                return pb;
            }
            var entry2 = pbdir.read_name();
            while ( entry2 != null )
            {
                var contents = FsoFramework.FileHandling.read( GLib.Path.build_filename( storagedir, pbdirname, entry2 ) );
                var components = contents.split( ":" );
                if ( components.length == 2 )
                {
                    var index = int.parse( entry2 );
                    //FIXME: Use relational syntax in Vala 0.7.11
                    if ( mindex <= index && index <= maxdex )
                    {
                        pb += FreeSmartphone.GSM.SIMEntry( index, components[0], components[1] );
                    }
                }
                else
                {
                    logger.warning( @"Invalid format in Phonebook entry at $storagedir/$pbdirname/$entry2" );
                }
                entry2 = pbdir.read_name();
            }
        }
        return pb;
    }
}

/**
 * @interface PhonebookHandler
 */
public interface FsoGsm.PhonebookHandler : FsoFramework.AbstractObject
{
    public abstract PhonebookStorage storage { get; set; }
}

/**
 * @class AtPhonebookHandler
 **/
public class FsoGsm.AtPhonebookHandler : FsoGsm.PhonebookHandler, FsoFramework.AbstractObject
{
    public PhonebookStorage storage { get; set; }

    public AtPhonebookHandler()
    {
        assert( theModem != null ); // Can't create PB handler before modem
        theModem.signalStatusChanged.connect( onModemStatusChanged );
    }

    public override string repr()
    {
        return storage != null ? storage.repr() : "<None>";
    }

    public void onModemStatusChanged( FsoGsm.Modem modem, FsoGsm.Modem.Status status )
    {
        switch ( status )
        {
            case Modem.Status.ALIVE_SIM_READY:
                simIsReady();
                break;
            default:
                break;
        }
    }

    public async void simIsReady()
    {
        yield syncWithSim();
    }

    public T[] copy<T>( T[] array )
    {
        T[] result = new T[] {};
        foreach ( T t in array )
        {
            result += t;
        }
        return result;
    }

    public async void syncWithSim()
    {
        // gather IMSI
        var cimi = theModem.createAtCommand<PlusCIMI>( "+CIMI" );
        var response = yield theModem.processAtCommandAsync( cimi, cimi.execute() );
        if ( cimi.validate( response ) != Constants.AtResponse.VALID )
        {
            logger.warning( "Can't synchronize PB storage with SIM" );
            return;
        }

        // create Storage for current IMSI
        storage = new PhonebookStorage( cimi.value );

        // retrieve all known phonebooks
        var cmd = theModem.createAtCommand<PlusCPBS>( "+CPBS" );
        response = yield theModem.processAtCommandAsync( cmd, cmd.test() );
        if ( cmd.validateTest( response ) != Constants.AtResponse.VALID )
        {
            logger.warning( "Can't parse phonebook result" );
            return;
        }

        // NOTE: Work around a reentrancy issue by copying the phonebooks
        // FIXME: This has to be investigated in more detail!
        var phonebooks = copy<string>( cmd.phonebooks );

        foreach ( var pbcode in phonebooks )
        {
            var cpbr = theModem.createAtCommand<PlusCPBR>( "+CPBR" );
            var answer = yield theModem.processAtCommandAsync( cpbr, cpbr.test( pbcode ) );
            if ( cpbr.validateTest( answer ) == Constants.AtResponse.VALID )
            {
                assert( logger.debug( @"Found phonebook '$pbcode' w/ indices $(cpbr.min)-$(cpbr.max)" ) );
                response = yield theModem.processAtCommandAsync( cpbr, cpbr.issue( pbcode, cpbr.min, cpbr.max ) );

                var valid = cpbr.validateMulti( response );
                if ( valid != Constants.AtResponse.VALID && valid != Constants.AtResponse.CME_ERROR_022_NOT_FOUND )
                {
                    logger.warning( @"Can't parse PB $pbcode" );
                    continue;
                }
                storage.addPhonebook( pbcode, cpbr.min, cpbr.max, cpbr.phonebook );
            }
        }
    }
}

// vim:ts=4:sw=4:expandtab
