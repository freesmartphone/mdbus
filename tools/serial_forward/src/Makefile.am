include $(top_srcdir)/Makefile.decl

NULL =

INCLUDES = \
	$(FSO_CFLAGS) \
	$(GLIB_CFLAGS) \
	-include $(CONFIG_HEADER) \
	$(NULL)

bin_PROGRAMS = \
	serial_forward \
	pty_forward \
	$(NULL)

serial_forward_SOURCES = \
	forward.c \
	forward.h \
	hsuart.h \
	$(NULL)

serial_forward_LDFLAGS = \
	-all-static

pty_forward_SOURCES = \
	pty_forward.c \
	$(NULL)

pty_forward_LDADD = \
	-lutil

CLEANFILES = \
	*.o \
	$(NULL)

MAINTAINERCLEANFILES = \
	Makefile.in \
	$(NULL)
