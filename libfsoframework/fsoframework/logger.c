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
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>




enum  {
	FSO_FRAMEWORK_ABSTRACT_LOGGER_DUMMY_PROPERTY
};
static void fso_framework_abstract_logger_real_write (FsoFrameworkAbstractLogger* self, const char* message);
static gpointer fso_framework_abstract_logger_parent_class = NULL;
static void fso_framework_abstract_logger_finalize (GObject* obj);
struct _FsoFrameworkFileLoggerPrivate {
	gint file;
};

#define FSO_FRAMEWORK_FILE_LOGGER_GET_PRIVATE(o) (G_TYPE_INSTANCE_GET_PRIVATE ((o), FSO_FRAMEWORK_TYPE_FILE_LOGGER, FsoFrameworkFileLoggerPrivate))
enum  {
	FSO_FRAMEWORK_FILE_LOGGER_DUMMY_PROPERTY
};
static gpointer fso_framework_file_logger_parent_class = NULL;
static void fso_framework_file_logger_finalize (GObject* obj);



static void fso_framework_abstract_logger_real_write (FsoFrameworkAbstractLogger* self, const char* message) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (message != NULL);
}


void fso_framework_abstract_logger_write (FsoFrameworkAbstractLogger* self, const char* message) {
	FSO_FRAMEWORK_ABSTRACT_LOGGER_GET_CLASS (self)->write (self, message);
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
		fso_framework_abstract_logger_write (self, message);
	}
}


void fso_framework_abstract_logger_info (FsoFrameworkAbstractLogger* self, const char* message) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (message != NULL);
	if (self->level >= ((guint) G_LOG_LEVEL_INFO)) {
		fso_framework_abstract_logger_write (self, message);
	}
}


void fso_framework_abstract_logger_warning (FsoFrameworkAbstractLogger* self, const char* message) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (message != NULL);
	if (self->level >= ((guint) G_LOG_LEVEL_WARNING)) {
		fso_framework_abstract_logger_write (self, message);
	}
}


void fso_framework_abstract_logger_error (FsoFrameworkAbstractLogger* self, const char* message) {
	g_return_if_fail (self != NULL);
	g_return_if_fail (message != NULL);
	if (self->level >= ((guint) G_LOG_LEVEL_ERROR)) {
		fso_framework_abstract_logger_write (self, message);
	}
}


static void fso_framework_abstract_logger_class_init (FsoFrameworkAbstractLoggerClass * klass) {
	fso_framework_abstract_logger_parent_class = g_type_class_peek_parent (klass);
	G_OBJECT_CLASS (klass)->finalize = fso_framework_abstract_logger_finalize;
	FSO_FRAMEWORK_ABSTRACT_LOGGER_CLASS (klass)->write = fso_framework_abstract_logger_real_write;
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
	gint flags;
	char* _tmp2;
	const char* _tmp1;
	g_return_if_fail (self != NULL);
	g_return_if_fail (filename != NULL);
	if (self->priv->file != (-1)) {
		char* _tmp0;
		_tmp0 = NULL;
		((FsoFrameworkAbstractLogger*) self)->destination = (_tmp0 = NULL, ((FsoFrameworkAbstractLogger*) self)->destination = (g_free (((FsoFrameworkAbstractLogger*) self)->destination), NULL), _tmp0);
		close (self->priv->file);
	}
	flags = (O_EXCL | O_CREAT) | O_WRONLY;
	if (append) {
		flags = flags | O_APPEND;
	}
	self->priv->file = open (filename, flags, S_IRWXU);
	_tmp2 = NULL;
	_tmp1 = NULL;
	((FsoFrameworkAbstractLogger*) self)->destination = (_tmp2 = (_tmp1 = filename, (_tmp1 == NULL) ? NULL : g_strdup (_tmp1)), ((FsoFrameworkAbstractLogger*) self)->destination = (g_free (((FsoFrameworkAbstractLogger*) self)->destination), NULL), _tmp2);
}


static void fso_framework_file_logger_class_init (FsoFrameworkFileLoggerClass * klass) {
	fso_framework_file_logger_parent_class = g_type_class_peek_parent (klass);
	g_type_class_add_private (klass, sizeof (FsoFrameworkFileLoggerPrivate));
	G_OBJECT_CLASS (klass)->finalize = fso_framework_file_logger_finalize;
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




