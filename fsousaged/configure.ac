AC_INIT([fsousaged], [0.9.5], [smartphones-userland@linuxtogo.org], [fsousaged])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CC
AM_PROG_CC_C_O
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

VALA_REQUIRED=0.12.0
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
m4_ifdef([AM_PROG_VALAC], [AM_PROG_VALAC([$VALA_REQUIRED])])

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GLIB_REQUIRED=2.26.0
GEE_REQUIRED=0.5.0
FSO_GLIB_REQUIRED=2010.05.11.2
FSO_FRAMEWORK_REQUIRED=0.2.3

# glib and friends
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

# gee
PKG_CHECK_MODULES(GEE,
  gee-1.0 >= $GEE_REQUIRED)
AC_SUBST(GEE_CFLAGS)
AC_SUBST(GEE_LIBS)

# dbus conf directory
DBUS_DIR="`$PKG_CONFIG --variable=sysconfdir dbus-1`"
if (test -z "{DBUS_DIR}"); then
  DBUS_DIR="${sysconfdir}/dbus-1"
else
  DBUS_DIR="$DBUS_DIR/dbus-1"
fi
AC_SUBST(DBUS_DIR)

# dbus service directory
DBUS_SERVICE_DIR="`$PKG_CONFIG --variable=session_bus_services_dir dbus-1`"
if (test -z "{DBUS_SERVICE_DIR}"); then
  DBUS_SERVICE_DIR="${datadir}/dbus-1/services"
fi
AC_SUBST(DBUS_SERVICE_DIR)
AC_DEFINE_UNQUOTED([DBUS_SERVICE_DIR], ["${DBUS_SERVICE_DIR}"], [dbus service activation dir])

# dbus system service directory
DBUS_SYSTEM_SERVICE_DIR="`echo $DBUS_SERVICE_DIR | sed -e s,services,system-services,g`"
AC_SUBST(DBUS_SYSTEM_SERVICE_DIR)
AC_DEFINE_UNQUOTED([DBUS_SYSTEM_SERVICE_DIR], ["${DBUS_SYSTEM_SERVICE_DIR}"], [dbus system service activation dir])

# fso-glib and framework
PKG_CHECK_MODULES(FSO,
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED
  fsoframework-2.0 >= $FSO_FRAMEWORK_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

# check for debugging
AC_ARG_ENABLE(debug,
  [  --enable-debug            Enable debug build (default=disabled)],
  [debug=$enableval],
  [debug="no"])
AM_CONDITIONAL( [WANT_DEBUG], [test x"$debug" = x"yes"])

# git version
GITV=`cat ../.git/refs/heads/master || echo "unknown"`
AC_DEFINE_UNQUOTED([PACKAGE_GITV], ["${GITV}"], [git version])

AC_CONFIG_FILES([
  Makefile
  conf/Makefile
  conf/default/Makefile
  conf/htc_qualcomm_dream/Makefile
  conf/htcleo/Makefile
  conf/openmoko_gta/Makefile
  conf/nexusone/Makefile
  conf/palm_pre/Makefile
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
#
# Info
#
echo
echo
echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE_NAME $PACKAGE_VERSION-$GITV"
echo "------------------------------------------------------------------------"
echo
echo "Configuration Options:"
echo
echo "  prefix..................: $prefix"
echo
echo "  debug...................: $debug"
echo
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
