/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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

//===========================================================================
void test_file_logger_new()
//===========================================================================
{
    FileUtils.remove( TEST_FILE_NAME );

    var logger = new FileLogger( TEST_LOG_DOMAIN );
    logger.setFile( TEST_FILE_NAME, false );
    logger.setLevel( LogLevelFlags.LEVEL_DEBUG );

    logger.debug( "foo" );

    var file = File.new_for_path( TEST_FILE_NAME );

    assert( file.query_exists( null ) );

    var stream = new DataInputStream( file.read( null ) );
    var firstline = stream.read_line( null, null );

    assert ( "foo" in firstline );
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
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);

    Test.add_func ("/FileLogger/new", test_file_logger_new);
    Test.add_func ("/SyslogLogger/new", test_syslog_logger_new);

    Test.run ();
}
