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
void test_common_create_logger()
//===========================================================================
{
    var logger = createLogger( TEST_LOG_DOMAIN );
    logger.debug( "debug" );
    logger.info( "info" );
    logger.warning( "warning" );
    logger.error( "error" );
}

//===========================================================================
void test_common_masterkeyfile()
//===========================================================================
{
    var mkf = theMasterKeyFile();
}
    
//===========================================================================
void main (string[] args)
//===========================================================================
{
    Test.init (ref args);

    Test.add_func ("/Common/createLogger", test_common_create_logger);
    Test.add_func ("/Common/masterKeyFile", test_common_masterkeyfile);    

    Test.run ();
}
