include $(top_srcdir)/Makefile.decl

NULL =

SUBDIRS = \
	src \
	vapi \
	$(NULL)

if WANT_DATAFILES
SUBDIRS += \
	conf \
	data \
	$(NULL)
endif

DISTCHECK_CONFIGURE_FLAGS = \
	--disable-datafiles \
	--enable-cmtspeechdata \
	--enable-samplerate \
	$(NULL)

MAINTAINERCLEANFILES = \
	aclocal.m4 compile config.guess config.sub \
	configure depcomp install-sh ltmain.sh     \
	Makefile.in missing config.h.in            \
	mkinstalldirs \
	$(NULL)
