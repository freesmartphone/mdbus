m4_define([fsousaged_released], [0])
m4_define([fsousaged_base_version], [0.11.0])
m4_define([fsousaged_maybe_gitrev], m4_if(fsousaged_released, [1], [], [m4_esyscmd([git show-ref --hash=5 HEAD | tr -d '\n\r'])]))
m4_define([fsousaged_version], m4_if(fsousaged_released, [1], [fsousaged_base_version], [fsousaged_base_version-fsousaged_maybe_gitrev]))

AC_INIT([fsousaged], fsousaged_version, [smartphones-userland@linuxtogo.org], [fsousaged])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PREREQ([2.65])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2 no-dist-gzip])
AM_MAINTAINER_MODE([enable])

AC_PROG_CC
AM_PROG_CC_C_O
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL
PKG_PROG_PKG_CONFIG([0.21])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

#########################################################################################
# Vala building options -- allows tarball builds without installing vala
#########################################################################################

VALA_REQUIRED=0.14.2

AC_ARG_ENABLE([vala], AS_HELP_STRING([--enable-vala],[Enable building from Vala sources]),
              [enable_vala=$enableval], [enable_vala=no])

# Force Vala for non-release builds
m4_if(fsosystem_released, [1], [],
      [
        enable_vala=yes
        echo "Vala compiler required for non-release builds; requiring Vala..."
      ])

if test "x$enable_vala" = "xyes" ; then
    AM_PROG_VALAC([$VALA_REQUIRED])
    if test "x$VALAC" = "x" ; then
        AC_MSG_ERROR([Vala requested but valac is not installed])
    fi
fi

AM_CONDITIONAL([HAVE_VALA], [test "x$enable_vala" = "xyes"])

#########################################################################################
# Check for various dependencies
#########################################################################################

GLIB_REQUIRED=2.26.0
GEE_REQUIRED=0.5.0
FSO_GLIB_REQUIRED=2012.04.18.1
FSO_REQUIRED=0.10.0

PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

PKG_CHECK_MODULES(GEE,
  gee-1.0 >= $GEE_REQUIRED)
AC_SUBST(GEE_CFLAGS)
AC_SUBST(GEE_LIBS)

PKG_CHECK_MODULES(FSO,
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED
  fsoframework-2.0 >= $FSO_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

#########################################################################################
# dbus conf directory
#########################################################################################

DBUS_DIR="`$PKG_CONFIG --variable=sysconfdir dbus-1`"
if (test -z "{DBUS_DIR}"); then
  DBUS_DIR="${sysconfdir}/dbus-1"
else
  DBUS_DIR="$DBUS_DIR/dbus-1"
fi
AC_SUBST(DBUS_DIR)

#########################################################################################
# dbus conf directory
#########################################################################################

AC_ARG_WITH(dbusconfdir, AC_HELP_STRING([--with-dbusconfdir=PATH], [path to D-Bus config directory]),
			[path_dbusconf=${withval}], [path_dbusconf="`$PKG_CONFIG --variable=sysconfdir dbus-1`"])

if (test -z "${path_dbusconf}"); then
  DBUS_DIR="${sysconfdir}/dbus-1"
else
  DBUS_DIR="${path_dbusconf}/dbus-1"
fi
AC_SUBST(DBUS_DIR)

#########################################################################################
# dbus service directory
#########################################################################################

AC_ARG_WITH(dbusservicedir, AC_HELP_STRING([--with-dbusdatadir=PATH], [path to D-Bus data directory]),
			[path_dbusdata=${withval}], [path_dbusdata="`$PKG_CONFIG --variable=datadir dbus-1`"])

if (test -z "${path_dbusdata}"); then
	DBUS_SYSTEM_SERVICE_DIR="${datadir}/dbus-1/system-services"
else
	DBUS_SYSTEM_SERVICE_DIR="${path_dbusdata}/dbus-1/system-services"
fi
AC_SUBST(DBUS_SYSTEM_SERVICE_DIR)

#########################################################################################
# check for debugging
#########################################################################################

AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [enable_debug=$enableval],
  [enable_debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$enable_debug" = x"yes"])

#########################################################################################
# output
#########################################################################################

AC_CONFIG_FILES([
  Makefile
  conf/Makefile
  conf/default/Makefile
  conf/htc_qualcomm_dream/Makefile
  conf/htcleo/Makefile
  conf/openmoko_gta/Makefile
  conf/nexusone/Makefile
  conf/palm_pre/Makefile
  conf/herring/Makefile
  data/org.freesmartphone.ousaged.service
  data/Makefile
  src/Makefile
  src/lib/Makefile
  src/bin/Makefile
  src/plugins/Makefile
  src/plugins/dbus_service/Makefile
  src/plugins/lowlevel_android/Makefile
  src/plugins/lowlevel_kernel26/Makefile
  src/plugins/lowlevel_kernel26_staysalive/Makefile
  src/plugins/lowlevel_openmoko/Makefile
  src/plugins/lowlevel_palmpre/Makefile
  tests/Makefile
])
AC_OUTPUT

#########################################################################################
# Info
#########################################################################################

echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE_NAME $PACKAGE_VERSION"
echo "------------------------------------------------------------------------"
echo
echo "Configuration Options:"
echo
echo "  Vala....................: $enable_vala"
echo
echo "  Vala Compiler...........: ${VALAC}"
echo
echo "  prefix..................: $prefix"
echo
echo "  debug...................: $enable_debug"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
