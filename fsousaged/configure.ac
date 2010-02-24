AC_INIT([fsousaged], [0.9.1.2], [smartphones-userland@linuxtogo.org], [fsousaged])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PROG_CC
AM_PROG_CC_C_O
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

VALA_REQUIRED=0.7.8
GLIB_REQUIRED=2.18.0
GEE_REQUIRED=0.5.0
DBUS_REQUIRED=1.2.1
DBUS_GLIB_REQUIRED=0.76
FSO_GLIB_REQUIRED=0.2.0
FSO_REQUIRED=0.2.3

# vala
PKG_CHECK_MODULES(VALA,
  vala-1.0 >= $VALA_REQUIRED)

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

# dbus and dbus-glib
PKG_CHECK_MODULES(DBUS,
  dbus-1 >= $DBUS_REQUIRED
  dbus-glib-1 >= $DBUS_GLIB_REQUIRED)
AC_SUBST(DBUS_CFLAGS)
AC_SUBST(DBUS_LIBS)

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

# fso-glib and framework
PKG_CHECK_MODULES(FSO,
  fso-glib-1.0 >= $FSO_GLIB_REQUIRED
  fsoframework-2.0 >= $FSO_REQUIRED)
AC_SUBST(FSO_CFLAGS)
AC_SUBST(FSO_LIBS)

# git version
GITV=`cat ../.git/refs/heads/master || echo "unknown"`
AC_DEFINE_UNQUOTED([PACKAGE_GITV], ["${GITV}"], [git version])

AC_CONFIG_FILES([
  Makefile
  conf/Makefile
  conf/default/Makefile
  conf/openmoko_gta/Makefile
  data/org.freesmartphone.ousaged.service
  data/Makefile
  src/Makefile
  src/lib/Makefile
  src/bin/Makefile
  src/plugins/Makefile
  src/plugins/dbus_service/Makefile
  src/plugins/lowlevel_kernel26/Makefile
  src/plugins/lowlevel_openmoko/Makefile
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
echo "------------------------------------------------------------------------"
echo
echo "Now type 'make' to compile and 'make install' to install this package."
