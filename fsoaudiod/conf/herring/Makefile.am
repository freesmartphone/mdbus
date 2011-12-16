include $(top_srcdir)/Makefile.decl

NULL=
THISDIR = `basename $$PWD`
SUBDIRS = alsa-default

confdir = $(sysconfdir)/freesmartphone/conf/$(THISDIR)
dist_conf_DATA = \
	fsoaudiod.conf \
	alsa.conf \
	policy.conf \
	$(NULL)

MAINTAINERCLEANFILES = Makefile.in
