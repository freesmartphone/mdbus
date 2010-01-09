/**
 * Copyright (C) 2009-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

using GLib;
using FsoFramework;

const string TEST_FILE_NAME = "/tmp/logfile.txt";
const string TEST_LOG_DOMAIN = "my.logging.domain";

const string TEST_LOG_KEYFILE_NAME = ".testlogger.ini";
const string TEST_LOG_KEYFILE = ".testlogger.ini";

//===========================================================================
void test_logger_conversions()
//===========================================================================
{
    assert ( AbstractLogger.levelToString( LogLevelFlags.LEVEL_DEBUG ) == "DEBUG" );
    assert ( AbstractLogger.levelToString( LogLevelFlags.LEVEL_INFO ) == "INFO" );
    assert ( AbstractLogger.levelToString( LogLevelFlags.LEVEL_WARNING ) == "WARNING" );
    assert ( AbstractLogger.levelToString( LogLevelFlags.LEVEL_ERROR ) == "ERROR" );

    assert ( AbstractLogger.stringToLevel( "debug" ) == LogLevelFlags.LEVEL_DEBUG );
    assert ( AbstractLogger.stringToLevel( "info" ) == LogLevelFlags.LEVEL_INFO );
    assert ( AbstractLogger.stringToLevel( "warning" ) == LogLevelFlags.LEVEL_WARNING );
    assert ( AbstractLogger.stringToLevel( "error" ) == LogLevelFlags.LEVEL_ERROR );

    assert ( AbstractLogger.stringToLevel( "DEBUG" ) == LogLevelFlags.LEVEL_DEBUG );
    assert ( AbstractLogger.stringToLevel( "INFO" ) == LogLevelFlags.LEVEL_INFO );
    assert ( AbstractLogger.stringToLevel( "WARNING" ) == LogLevelFlags.LEVEL_WARNING );
    assert ( AbstractLogger.stringToLevel( "ERROR" ) == LogLevelFlags.LEVEL_ERROR );
}

//===========================================================================
void test_null_logger_new()
//===========================================================================
{
    var logger = new NullLogger( TEST_LOG_DOMAIN );
    logger.setLevel( LogLevelFlags.LEVEL_DEBUG );

    logger.debug( "foo" );
    logger.info( "bar" );
    logger.warning( "ham" );
    logger.error( "eggs" );
}

//===========================================================================
void test_file_logger_new()
//===========================================================================
{
    FileUtils.remove( TEST_FILE_NAME );

    var logger = new FileLogger( TEST_LOG_DOMAIN );
    logger.setFile( TEST_FILE_NAME, false );
    logger.setLevel( LogLevelFlags.LEVEL_DEBUG );

    logger.debug( "foo" );
    logger.info( "bar" );
    logger.warning( "ham" );
    logger.error( "eggs" );

    var file = File.new_for_path( TEST_FILE_NAME );
    assert( file.query_exists( null ) );

    var stream = new DataInputStream( file.read( null ) );
    var line1 = stream.read_line( null, null );
    assert ( "DEBUG" in line1 && "foo" in line1 );
    var line2 = stream.read_line( null, null );
    assert ( "INFO" in line2 && "bar" in line2 );
    var line3 = stream.read_line( null, null );
    assert ( "WARNING" in line3 && "ham" in line3 );
    var line4 = stream.read_line( null, null );
    assert ( "ERROR" in line4 && "eggs" in line4 );
}

class ReprDelegateTester
{
    public bool called;

    public string repr()
    {
        called = true;
        return "<representation>";
    }
}

//===========================================================================
void test_logger_reprdelegate()
//===========================================================================
{
    var logger = new FileLogger( TEST_LOG_DOMAIN );
    logger.setFile( "/dev/null", false );

    var r = new ReprDelegateTester();
    r.called = false;
    logger.setReprDelegate( r.repr );

    logger.warning( "foo" );

    assert ( r.called );
}

//===========================================================================
void test_syslog_logger_new()
//===========================================================================
{
    var logger = new SyslogLogger( TEST_LOG_DOMAIN );
    logger.setLevel( LogLevelFlags.LEVEL_DEBUG );

    logger.debug( "foo" );
}

//===========================================================================
void test_logger_create_from_keyfilename()
//===========================================================================
{
    FsoFramework.Logger logger = Logger.createFromKeyFileName( TEST_LOG_KEYFILE_NAME, "nologger", TEST_LOG_DOMAIN );
    assert( Type.from_instance( logger ) == typeof( StdErrLogger ) ); // auto fall back to StdErr

    logger = Logger.createFromKeyFileName( TEST_LOG_KEYFILE_NAME, "stderr", TEST_LOG_DOMAIN );
    assert( Type.from_instance( logger ) == typeof( StdErrLogger ) );
    assert( logger.getLevel() == LogLevelFlags.LEVEL_DEBUG );

    logger = Logger.createFromKeyFileName( TEST_LOG_KEYFILE_NAME, "syslog", TEST_LOG_DOMAIN );
    assert( Type.from_instance( logger ) == typeof( SyslogLogger ) );
    assert( logger.getLevel() == LogLevelFlags.LEVEL_INFO );

    logger = Logger.createFromKeyFileName( TEST_LOG_KEYFILE_NAME, "file", TEST_LOG_DOMAIN );
    assert( Type.from_instance( logger ) == typeof( FileLogger ) );
    assert( logger.getLevel() == LogLevelFlags.LEVEL_WARNING );
    assert( logger.getDestination() == "log.txt" );
}

//===========================================================================
void test_logger_create_from_keyfile()
//===========================================================================
{
    var smk = new SmartKeyFile();
    smk.loadFromFile( TEST_LOG_KEYFILE );

    FsoFramework.Logger logger = Logger.createFromKeyFile( smk, "nologger", TEST_LOG_DOMAIN );
    assert( Type.from_instance( logger ) == typeof( StdErrLogger ) );

    logger = Logger.createFromKeyFile( smk, "stderr", TEST_LOG_DOMAIN );
    assert( Type.from_instance( logger ) == typeof( StdErrLogger ) );
    assert( logger.getLevel() == LogLevelFlags.LEVEL_DEBUG );

    logger = Logger.createFromKeyFile( smk, "syslog", TEST_LOG_DOMAIN );
    assert( Type.from_instance( logger ) == typeof( SyslogLogger ) );
    assert( logger.getLevel() == LogLevelFlags.LEVEL_INFO );

    logger = Logger.createFromKeyFile( smk, "file", TEST_LOG_DOMAIN );
    assert( Type.from_instance( logger ) == typeof( FileLogger ) );
    assert( logger.getLevel() == LogLevelFlags.LEVEL_WARNING );
    assert( logger.getDestination() == "log.txt" );
}

//===========================================================================
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);

    Test.add_func ("/Logger/Conversions", test_logger_conversions);
    Test.add_func ("/Logger/ReprDelegate", test_logger_reprdelegate);
    Test.add_func ("/NullLogger/New", test_null_logger_new);
    Test.add_func ("/FileLogger/New", test_file_logger_new);
    Test.add_func ("/SyslogLogger/New", test_syslog_logger_new);
    Test.add_func ("/Logger/CreateFromKeyFileName", test_logger_create_from_keyfilename);
    Test.add_func ("/Logger/CreateFromKeyFile", test_logger_create_from_keyfile);

    Test.run ();
}
