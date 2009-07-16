AC_INIT([libfsoframework], [0.2.0.0], [smartphones-userland@linuxtogo.org], [libfsoframework])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])

AC_PROG_CC
AM_PROG_CC_C_O
AC_GNU_SOURCE
AC_DISABLE_STATIC
AC_PROG_LIBTOOL

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

#
# pkg-config requirements
#
PKG_PROG_PKG_CONFIG

VALA_REQUIRED=0.7.3
DBUS_REQUIRED=1.2.1
DBUS_GLIB_REQUIRED=0.76
GLIB_REQUIRED=2.18.0
ALSA_REQUIRED=0.20
FSOBASICS_REQUIRED=0.8.0.0

# vala
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
PKG_CHECK_MODULES(VALA,
  vala-1.0 >= $VALA_REQUIRED)

#
# vala vapi files
#
VALA_VAPIDIR=`$PKG_CONFIG --variable=vapidir vala-1.0`
AC_SUBST(VALA_VAPIDIR)

AC_MSG_NOTICE([checking for misc-vapi...])
if ! test -f "$VALA_VAPIDIR/linux26.vapi"; then
  AC_MSG_ERROR([linux26.vapi not found.])
fi
if ! test -f "$VALA_VAPIDIR/libasound.vapi"; then
  AC_MSG_ERROR([libasound.vapi not found.])
fi
if ! test -f "$VALA_VAPIDIR/libcanberra.vapi"; then
  AC_MSG_ERROR([libcanberra.vapi not found.])
fi

# glib and friends
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

# dbus and dbus-glib
PKG_CHECK_MODULES(DBUS,
  dbus-1 >= $DBUS_REQUIRED
  dbus-glib-1 >= $DBUS_GLIB_REQUIRED)
AC_SUBST(DBUS_CFLAGS)
AC_SUBST(DBUS_LIBS)

# alsa
PKG_CHECK_MODULES(ALSA,
  alsa >= $ALSA_REQUIRED)
AC_SUBST(ALSA_CFLAGS)
AC_SUBST(ALSA_LIBS)

# libfsobasics
PKG_CHECK_MODULES(FSOBASICS,
  fsobasics-2.0 >= $FSOBASICS_REQUIRED)
AC_SUBST(FSOBASICS_CFLAGS)
AC_SUBST(FSOBASICS_LIBS)

#
# we need eventfd
#
AC_CHECK_HEADER(sys/eventfd.h, , [AC_MSG_ERROR(
[Couldn't find sys/eventfd.h... your glibc is too old :(] )])

#
# output
#
AC_CONFIG_FILES([Makefile
  fsoframework-2.0.pc
  fsoframework/Makefile
  tests/Makefile])

AC_OUTPUT

#
# Info
#
echo
echo
echo
echo "------------------------------------------------------------------------"
echo "$PACKAGE_NAME $PACKAGE_VERSION"
echo "------------------------------------------------------------------------"
echo
echo "Configuration Options Summary:"
echo
echo "  Compilation...............: make"
echo
echo "  Installation..............: make install"
echo
echo "    prefix..................: $prefix"
echo
