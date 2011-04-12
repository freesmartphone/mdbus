/*
 * (c) 2011 Simon Busch <morphis@gravedo.de>
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
using FsoFramework;

namespace FsoApp
{
    public class ApplicationStorage : AbstractObject
    {
        // NOTE cannot be public as we want to use the += syntax to add
        // elements to the array; use list_applications method
        // the available applications.
        private ApplicationInfo[] applications;
        private string[] app_searchpath;
        private bool skip_incompatible;

        private const string DESKTOP_ENTRY = "Desktop Entry";

        public ApplicationStorage()
        {
            app_searchpath = theConfig.stringListValue( "fsoapp", "app_searchpath",
                                                          new string[] { "/usr/share/applications", "/usr/local/share/applications" } );
            skip_incompatible = theConfig.boolValue( "fsoapp", "skip_incompatible", false );
            rescan();
        }

        public override string repr()
        {
            return "<>";
        }

        public ApplicationInfo[] list_all()
        {
            return applications;
        }

        public ApplicationInfo? find_application_by_name( string appname )
        {
            ApplicationInfo? result = null;

            foreach ( var application in applications )
            {
                if ( appname.ascii_casecmp( application.appname ) != 0 )
                {
                    result = application;
                    break;
                }
            }

            return result;
        }

        public ApplicationInfo[] find_application_by_interface( string ifname )
        {
            ApplicationInfo[] result = new ApplicationInfo[] { };

            foreach ( var application in applications )
            {
                if ( ifname in application.provided_interfaces )
                {
                    result += application;
                }
            }

            return result;
        }

        public void rescan()
        {
            FileInfo finfo;
            ApplicationInfo appinfo;
            string filename;
            SmartKeyFile smk;
            applications = new ApplicationInfo[] { };

            foreach ( var dir in app_searchpath )
            {
                logger.debug( @"Searching in $dir for *.desktop files ..." );
                var path = File.new_for_path( dir );
                try
                {
                    var iter = path.enumerate_children( FILE_ATTRIBUTE_STANDARD_NAME, 0 );

                    while ( ( finfo = iter.next_file() ) != null )
                    {
                        filename = finfo.get_name();
                        logger.debug( @"Found application named in file \"$filename\"" );

                        if ( filename.has_suffix( ".desktop" ) )
                        {
                            smk = new SmartKeyFile();
                            smk.loadFromFile( Path.build_filename( dir, filename ) );

                            if ( !smk.hasKey( DESKTOP_ENTRY, "X-FSO-AppName" ) )
                            {
                                logger.debug( @"Skipping $filename as it is not FSO compatible" );
                                continue;
                            }

                            appinfo = new ApplicationInfo();
                            appinfo.name = smk.stringValue( DESKTOP_ENTRY, "Name", "Unknown" );
                            appinfo.exec_info = smk.stringValue( DESKTOP_ENTRY, "Exec", "" );
                            appinfo.appname = smk.stringValue( DESKTOP_ENTRY, "X-FSO-AppName", "org.unknown" );
                            appinfo.categories = smk.stringListValue( DESKTOP_ENTRY, "Categories", new string[] { } );
                            appinfo.provided_interfaces = smk.stringListValue( DESKTOP_ENTRY, "X-FSO-ProvidedInterfaces", new string[] { } );

                            applications += appinfo;

                            logger.debug( @"Found application: name = $(appinfo.name), appname = $(appinfo.appname), exec_info = $(appinfo.exec_info)" );
                        }
                    }
                }
                catch ( GLib.Error err )
                {
                    logger.error( @"Could not retrieve all available applications from $dir: $(err.message)" );
                }
            }
        }
    }
}
