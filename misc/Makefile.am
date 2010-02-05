include $(top_srcdir)/Makefile.decl

NULL =

SUBDIRS = \
  vapi \
  $(NULL)
  
if MAKE_TESTS
  SUBDIRS += tests
endif

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = misc-vapi-1.0.pc

EXTRA_DIST += \
  MAINTAINERS \
  misc-vapi-1.0.pc.in \
  $(NULL)      

MAINTAINERCLEANFILES = \
  aclocal.m4 compile config.guess config.sub \
  configure depcomp install-sh ltmain.sh     \
  Makefile.in missing config.h.in            \
  mkinstalldirs *~ \
  $(NULL)
