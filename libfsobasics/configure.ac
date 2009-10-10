AC_INIT([libfsobasics], [0.8.3.2], [smartphones-userland@linuxtogo.org], [libfsobasics])
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

VALA_REQUIRED=0.7.7
MISC_VAPI_REQUIRED=0.5.0
GLIB_REQUIRED=2.18.0

# vala
AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)
PKG_CHECK_MODULES(VALA,
  vala-1.0 >= $VALA_REQUIRED)

#
# fso misc vapi files
#
PKG_CHECK_MODULES(MISC_VAPI,
	misc-vapi-1.0 >= $MISC_VAPI_REQUIRED)

# glib and friends
PKG_CHECK_MODULES(GLIB,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  gio-2.0 >= $GLIB_REQUIRED)
AC_SUBST(GLIB_CFLAGS)
AC_SUBST(GLIB_LIBS)

#
# we need eventfd
#
AC_CHECK_HEADER(sys/eventfd.h, , [AC_MSG_ERROR(
[Couldn't find sys/eventfd.h... your glibc is too old :(] )])

#
# output
#
AC_CONFIG_FILES([Makefile
  fsobasics-2.0.pc
  fsobasics/Makefile
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
echo "  Compilation...............: make"
echo
echo "  Installation..............: make install"
echo
echo "    prefix..................: $prefix"
echo
