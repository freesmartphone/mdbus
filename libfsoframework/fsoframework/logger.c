/**
 * Copyright (C) 2009 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

#include <fsoframework/logger.h>
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <syslog.h>




enum  {
	FSO_FRAMEWORK_ABSTRACT_LOGGER_DUMMY_PROPERTY
};
static void fso_framework_abstract_logger_real_write (FsoFrameworkAbstractLogger* self, const char* message);
static char* fso_framework_abstract_logger_real_format (FsoFrameworkAbstractLogger* self, const char* message, const char* level);
static gpointer fso_framework_abstract_logger_parent_class = NULL;
static void fso_framework_abstract_logger_finalize (GObject* obj);
struct _FsoFrameworkFileLoggerPrivate {
	gint file;
};

#define FSO_FRAMEWORK_FILE_LOGGER_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), FSO_FRAMEWORK_TYPE_FILE_LOGGER, FsoFrameworkFileLoggerPrivate))
enum  {
	FSO_FRAMEWORK_FILE_LOGGER_DUMMY_PROPERTY
};
static void fso_framework_file_logger_real_write (FsoFrameworkAbstractLogger* base, const char* message);
static gpointer fso_framework_file_logger_parent_class = NULL;
static void fso_framework_file_logger_finalize (GObject* obj);
enum  {
	FSO_FRAMEWORK_SYSLOG_LOGGER_DUMMY_PROPERTY
};
static void fso_framework_syslog_logger_real_write (FsoFrameworkAbstractLogger* base, const char* message);
static char* fso_framework_syslog_logger_real_format (FsoFrameworkAbstractLogger* base, const char* message, const char* level);
static gpointer fso_framework_syslog_logger_parent_class = NULL;
static int _vala_strcmp0 (const char * str1, const char * str2);



static void fso_framework_abstract_logger_real_write (FsoFrameworkAbstractLogger* self, const char* message) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (message != NULL);
}


void fso_framework_abstract_logger_write (FsoFrameworkAbstractLogger* self, const char* message) {
	FSO_FRAMEWORK_ABSTRACT_LOGGER_GET_CLASS (self)->write (self, message);
}


static char* fso_framework_abstract_logger_real_format (FsoFrameworkAbstractLogger* self, const char* message, const char* level) {
	GTimeVal _tmp0 = {0};
	GTimeVal t;
	char* _tmp1;
	char* _tmp2;
	char* str;
	g_return_val_if_fail (self != NULL, NULL);
	g_return_val_if_fail (message != NULL, NULL);
	g_return_val_if_fail (level != NULL, NULL);
	t = (g_get_current_time (&_tmp0), _tmp0);
	_tmp1 = NULL;
	_tmp2 = NULL;
	str = (_tmp2 = g_strdup_printf ("%s %s [%s] %s\n", _tmp1 = g_time_val_to_iso8601 (&t), self->domain, level, message), _tmp1 = (g_free (_tmp1), NULL), _tmp2);
	return str;
}


char* fso_framework_abstract_logger_format (FsoFrameworkAbstractLogger* self, const char* message, const char* level) {
	return FSO_FRAMEWORK_ABSTRACT_LOGGER_GET_CLASS (self)->format (self, message, level);
}


FsoFrameworkAbstractLogger* fso_framework_abstract_logger_construct (GType object_type, const char* domain) {
	FsoFrameworkAbstractLogger * self;
	char* _tmp1;
	const char* _tmp0;
	g_return_val_if_fail (domain != NULL, NULL);
	self = g_object_newv (object_type, 0, NULL);
	_tmp1 = NULL;
	_tmp0 = NULL;
	self->domain = (_tmp1 = (_tmp0 = domain, (_tmp0 == NULL) ? NULL : g_strdup (_tmp0)), self->domain = (g_free (self->domain), NULL), _tmp1);
	return self;
}


FsoFrameworkAbstractLogger* fso_framework_abstract_logger_new (const char* domain) {
	return fso_framework_abstract_logger_construct (FSO_FRAMEWORK_TYPE_ABSTRACT_LOGGER, domain);
}


void fso_framework_abstract_logger_setLevel (FsoFrameworkAbstractLogger* self, GLogLevelFlags level) {
	g_return_if_fail (self != NULL);
	self->level = (guint) level;
}


void fso_framework_abstract_logger_setDestination (FsoFrameworkAbstractLogger* self, const char* destination) {
	char* _tmp1;
	const char* _tmp0;
	g_return_if_fail (self != NULL);
	g_return_if_fail (destination != NULL);
	_tmp1 = NULL;
	_tmp0 = NULL;
	self->destination = (_tmp1 = (_tmp0 = destination, (_tmp0 == NULL) ? NULL : g_strdup (_tmp0)), self->destination = (g_free (self->destination), NULL), _tmp1);
}


void fso_framework_abstract_logger_debug (FsoFrameworkAbstractLogger* self, const char* message) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (message != NULL);
	if (self->level >= ((guint) G_LOG_LEVEL_DEBUG)) {
		char* _tmp0;
		_tmp0 = NULL;
		fso_framework_abstract_logger_write (self, _tmp0 = fso_framework_abstract_logger_format (self, message, "DEBUG"));
		_tmp0 = (g_free (_tmp0), NULL);
	}
}


void fso_framework_abstract_logger_info (FsoFrameworkAbstractLogger* self, const char* message) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (message != NULL);
	if (self->level >= ((guint) G_LOG_LEVEL_INFO)) {
		char* _tmp0;
		_tmp0 = NULL;
		fso_framework_abstract_logger_write (self, _tmp0 = fso_framework_abstract_logger_format (self, message, "INFO"));
		_tmp0 = (g_free (_tmp0), NULL);
	}
}


void fso_framework_abstract_logger_warning (FsoFrameworkAbstractLogger* self, const char* message) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (message != NULL);
	if (self->level >= ((guint) G_LOG_LEVEL_WARNING)) {
		char* _tmp0;
		_tmp0 = NULL;
		fso_framework_abstract_logger_write (self, _tmp0 = fso_framework_abstract_logger_format (self, message, "WARNING"));
		_tmp0 = (g_free (_tmp0), NULL);
	}
}


void fso_framework_abstract_logger_error (FsoFrameworkAbstractLogger* self, const char* message) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (message != NULL);
	if (self->level >= ((guint) G_LOG_LEVEL_ERROR)) {
		char* _tmp0;
		_tmp0 = NULL;
		fso_framework_abstract_logger_write (self, _tmp0 = fso_framework_abstract_logger_format (self, message, "ERROR"));
		_tmp0 = (g_free (_tmp0), NULL);
	}
}


static void fso_framework_abstract_logger_class_init (FsoFrameworkAbstractLoggerClass * klass) {
	fso_framework_abstract_logger_parent_class = g_type_class_peek_parent (klass);
	G_OBJECT_CLASS (klass)->finalize = fso_framework_abstract_logger_finalize;
	FSO_FRAMEWORK_ABSTRACT_LOGGER_CLASS (klass)->write = fso_framework_abstract_logger_real_write;
	FSO_FRAMEWORK_ABSTRACT_LOGGER_CLASS (klass)->format = fso_framework_abstract_logger_real_format;
}


static void fso_framework_abstract_logger_instance_init (FsoFrameworkAbstractLogger * self) {
	self->level = (guint) G_LOG_LEVEL_INFO;
}


static void fso_framework_abstract_logger_finalize (GObject* obj) {
	FsoFrameworkAbstractLogger * self;
	self = FSO_FRAMEWORK_ABSTRACT_LOGGER (obj);
	self->domain = (g_free (self->domain), NULL);
	self->destination = (g_free (self->destination), NULL);
	G_OBJECT_CLASS (fso_framework_abstract_logger_parent_class)->finalize (obj);
}


GType fso_framework_abstract_logger_get_type (void) {
	static GType fso_framework_abstract_logger_type_id = 0;
	if (fso_framework_abstract_logger_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (FsoFrameworkAbstractLoggerClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) fso_framework_abstract_logger_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (FsoFrameworkAbstractLogger), 0, (GInstanceInitFunc) fso_framework_abstract_logger_instance_init, NULL };
		fso_framework_abstract_logger_type_id = g_type_register_static (G_TYPE_OBJECT, "FsoFrameworkAbstractLogger", &g_define_type_info, G_TYPE_FLAG_ABSTRACT);
	}
	return fso_framework_abstract_logger_type_id;
}


static void fso_framework_file_logger_real_write (FsoFrameworkAbstractLogger* base, const char* message) {
	FsoFrameworkFileLogger * self;
	self = (FsoFrameworkFileLogger*) base;
	g_return_if_fail (message != NULL);
	g_assert (self->priv->file != (-1));
	write (self->priv->file, message, (gsize) strlen (message));
}


FsoFrameworkFileLogger* fso_framework_file_logger_construct (GType object_type, const char* domain) {
	FsoFrameworkFileLogger * self;
	g_return_val_if_fail (domain != NULL, NULL);
	self = (FsoFrameworkFileLogger*) fso_framework_abstract_logger_construct (object_type, domain);
	return self;
}


FsoFrameworkFileLogger* fso_framework_file_logger_new (const char* domain) {
	return fso_framework_file_logger_construct (FSO_FRAMEWORK_TYPE_FILE_LOGGER, domain);
}


void fso_framework_file_logger_setFile (FsoFrameworkFileLogger* self, const char* filename, gboolean append) {
	char* _tmp3;
	const char* _tmp2;
	g_return_if_fail (self != NULL);
	g_return_if_fail (filename != NULL);
	if (self->priv->file != (-1)) {
		char* _tmp0;
		_tmp0 = NULL;
		((FsoFrameworkAbstractLogger*) self)->destination = (_tmp0 = NULL, ((FsoFrameworkAbstractLogger*) self)->destination = (g_free (((FsoFrameworkAbstractLogger*) self)->destination), NULL), _tmp0);
		close (self->priv->file);
	}
	if (_vala_strcmp0 (filename, "stderr") == 0) {
		self->priv->file = fileno (stderr);
	} else {
		gint _tmp1;
		gint flags;
		_tmp1 = 0;
		if (append) {
			_tmp1 = O_APPEND;
		} else {
			_tmp1 = O_CREAT;
		}
		flags = O_WRONLY | _tmp1;
		self->priv->file = open (filename, flags, S_IRWXU);
	}
	if (self->priv->file == (-1)) {
		g_error ("logger.vala:118: %s", strerror (errno));
	}
	_tmp3 = NULL;
	_tmp2 = NULL;
	((FsoFrameworkAbstractLogger*) self)->destination = (_tmp3 = (_tmp2 = filename, (_tmp2 == NULL) ? NULL : g_strdup (_tmp2)), ((FsoFrameworkAbstractLogger*) self)->destination = (g_free (((FsoFrameworkAbstractLogger*) self)->destination), NULL), _tmp3);
}


static void fso_framework_file_logger_class_init (FsoFrameworkFileLoggerClass * klass) {
	fso_framework_file_logger_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (FsoFrameworkFileLoggerPrivate));
	G_OBJECT_CLASS (klass)->finalize = fso_framework_file_logger_finalize;
	FSO_FRAMEWORK_ABSTRACT_LOGGER_CLASS (klass)->write = fso_framework_file_logger_real_write;
}


static void fso_framework_file_logger_instance_init (FsoFrameworkFileLogger * self) {
	self->priv = FSO_FRAMEWORK_FILE_LOGGER_GET_PRIVATE (self);
	self->priv->file = -1;
}


static void fso_framework_file_logger_finalize (GObject* obj) {
	FsoFrameworkFileLogger * self;
	self = FSO_FRAMEWORK_FILE_LOGGER (obj);
	G_OBJECT_CLASS (fso_framework_file_logger_parent_class)->finalize (obj);
}


GType fso_framework_file_logger_get_type (void) {
	static GType fso_framework_file_logger_type_id = 0;
	if (fso_framework_file_logger_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (FsoFrameworkFileLoggerClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) fso_framework_file_logger_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (FsoFrameworkFileLogger), 0, (GInstanceInitFunc) fso_framework_file_logger_instance_init, NULL };
		fso_framework_file_logger_type_id = g_type_register_static (FSO_FRAMEWORK_TYPE_ABSTRACT_LOGGER, "FsoFrameworkFileLogger", &g_define_type_info, 0);
	}
	return fso_framework_file_logger_type_id;
}


static void fso_framework_syslog_logger_real_write (FsoFrameworkAbstractLogger* base, const char* message) {
	FsoFrameworkSyslogLogger * self;
	self = (FsoFrameworkSyslogLogger*) base;
	g_return_if_fail (message != NULL);
	syslog (LOG_DEBUG, "%s", message, NULL);
}


/**
     * Overridden, since syslog already includes a timestamp
     **/
static char* fso_framework_syslog_logger_real_format (FsoFrameworkAbstractLogger* base, const char* message, const char* level) {
	FsoFrameworkSyslogLogger * self;
	char* str;
	self = (FsoFrameworkSyslogLogger*) base;
	g_return_val_if_fail (message != NULL, NULL);
	g_return_val_if_fail (level != NULL, NULL);
	str = g_strdup_printf ("%s [%s] %s\n", ((FsoFrameworkAbstractLogger*) self)->domain, level, message);
	return str;
}


FsoFrameworkSyslogLogger* fso_framework_syslog_logger_construct (GType object_type, const char* domain) {
	FsoFrameworkSyslogLogger * self;
	char* basename;
	g_return_val_if_fail (domain != NULL, NULL);
	self = (FsoFrameworkSyslogLogger*) fso_framework_abstract_logger_construct (object_type, domain);
	basename = g_path_get_basename (g_get_prgname ());
	openlog (basename, LOG_PID | LOG_CONS, LOG_DAEMON);
	return self;
}


FsoFrameworkSyslogLogger* fso_framework_syslog_logger_new (const char* domain) {
	return fso_framework_syslog_logger_construct (FSO_FRAMEWORK_TYPE_SYSLOG_LOGGER, domain);
}


static void fso_framework_syslog_logger_class_init (FsoFrameworkSyslogLoggerClass * klass) {
	fso_framework_syslog_logger_parent_class = g_type_class_peek_parent (klass);
	FSO_FRAMEWORK_ABSTRACT_LOGGER_CLASS (klass)->write = fso_framework_syslog_logger_real_write;
	FSO_FRAMEWORK_ABSTRACT_LOGGER_CLASS (klass)->format = fso_framework_syslog_logger_real_format;
}


static void fso_framework_syslog_logger_instance_init (FsoFrameworkSyslogLogger * self) {
}


GType fso_framework_syslog_logger_get_type (void) {
	static GType fso_framework_syslog_logger_type_id = 0;
	if (fso_framework_syslog_logger_type_id == 0) {
		static const GTypeInfo g_define_type_info = { sizeof (FsoFrameworkSyslogLoggerClass), (GBaseInitFunc) NULL, (GBaseFinalizeFunc) NULL, (GClassInitFunc) fso_framework_syslog_logger_class_init, (GClassFinalizeFunc) NULL, NULL, sizeof (FsoFrameworkSyslogLogger), 0, (GInstanceInitFunc) fso_framework_syslog_logger_instance_init, NULL };
		fso_framework_syslog_logger_type_id = g_type_register_static (FSO_FRAMEWORK_TYPE_ABSTRACT_LOGGER, "FsoFrameworkSyslogLogger", &g_define_type_info, 0);
	}
	return fso_framework_syslog_logger_type_id;
}


static int _vala_strcmp0 (const char * str1, const char * str2) {
	if (str1 == NULL) {
		return -(str1 != str2);
	}
	if (str2 == NULL) {
		return str1 != str2;
	}
	return strcmp (str1, str2);
}




