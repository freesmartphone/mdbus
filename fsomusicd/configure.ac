AC_INIT([fsomusicd], [0.0.0], [frederik.sdun@googlemail.com], [fsomusicd])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(src/config.h)
AM_INIT_AUTOMAKE([dist-bzip2])

AC_PROG_CC
AM_PROG_CC_C_O
#AC_DISABLE_STATIC
AC_PROG_LIBTOOL


AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

GLIB_REQUIRED=2.12.0
DBUS_REQUIRED=0.76
VALA_REQUIRED=0.7.8
FSO_REQUIRED=0.2.2
GEE_REQUIRED=0.5.0

PKG_CHECK_MODULES(VALA,
  vala-1.0 >= $VALA_REQUIRED)

PKG_CHECK_MODULES(DEPS,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  dbus-glib-1 >= $DBUS_REQUIRED
  gstreamer-0.10
  fsobasics-2.0
  fso-glib-1.0 >= $FSO_REQUIRED
  fsoframework-2.0
  gee-1.0 >= $GEE_REQUIRED)

AC_SUBST(DEPS_CFLAGS)
AC_SUBST(DEPS_LIBS)

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


AC_CONFIG_FILES([
	Makefile
	data/Makefile
	src/Makefile])

AC_OUTPUT
