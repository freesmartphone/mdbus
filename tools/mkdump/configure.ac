AC_INIT([mkdump], [1.0.0], [mlauer@vanille-media.de], [mkdump])
AC_CONFIG_SRCDIR([Makefile.am])
AC_CONFIG_HEADERS(config.h)
AM_INIT_AUTOMAKE([dist-bzip2])
m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_GNU_SOURCE
AC_PROG_CC
AM_PROG_CC_C_O
AC_PROG_LIBTOOL

AC_PATH_PROG(VALAC, valac, valac)
AC_SUBST(VALAC)

AC_SUBST(CFLAGS)
AC_SUBST(CPPFLAGS)
AC_SUBST(LDFLAGS)

VALA_REQUIRED=0.9.6.1
GLIB_REQUIRED=2.12.0
FSO_BASICS_REQUIRED=0.9

PKG_CHECK_MODULES(VALA,
  vala-0.10 >= $VALA_REQUIRED)
AC_SUBST(VALA_CFLAGS)
AC_SUBST(VALA_LIBS)

PKG_CHECK_MODULES(DEPS,
  glib-2.0 >= $GLIB_REQUIRED
  gobject-2.0 >= $GLIB_REQUIRED
  fsobasics-2.0 >= $FSO_BASICS_REQUIRED)
AC_SUBST(DEPS_CFLAGS)
AC_SUBST(DEPS_LIBS)

AC_CONFIG_FILES([
	Makefile
])

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
