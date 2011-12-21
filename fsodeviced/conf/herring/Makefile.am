include $(top_srcdir)/Makefile.decl

NULL=
SUBDIRS = alsa-default
THISDIR = `basename $$PWD`

confdir = $(sysconfdir)/freesmartphone/conf/$(THISDIR)
dist_conf_DATA = \
	fsodeviced.conf \
	alsa.conf \
	$(NULL)

MAINTAINERCLEANFILES = Makefile.in
