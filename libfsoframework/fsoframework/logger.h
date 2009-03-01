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

#ifndef __FSOFRAMEWORK_LOGGER_H__
#define __FSOFRAMEWORK_LOGGER_H__

#include <glib.h>
#include <glib-object.h>
#include <stdlib.h>
#include <string.h>

G_BEGIN_DECLS


#define FSO_FRAMEWORK_TYPE_ABSTRACT_LOGGER (fso_framework_abstract_logger_get_type ())
#define FSO_FRAMEWORK_ABSTRACT_LOGGER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), FSO_FRAMEWORK_TYPE_ABSTRACT_LOGGER, FsoFrameworkAbstractLogger))
#define FSO_FRAMEWORK_ABSTRACT_LOGGER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), FSO_FRAMEWORK_TYPE_ABSTRACT_LOGGER, FsoFrameworkAbstractLoggerClass))
#define FSO_FRAMEWORK_IS_ABSTRACT_LOGGER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), FSO_FRAMEWORK_TYPE_ABSTRACT_LOGGER))
#define FSO_FRAMEWORK_IS_ABSTRACT_LOGGER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), FSO_FRAMEWORK_TYPE_ABSTRACT_LOGGER))
#define FSO_FRAMEWORK_ABSTRACT_LOGGER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), FSO_FRAMEWORK_TYPE_ABSTRACT_LOGGER, FsoFrameworkAbstractLoggerClass))

typedef struct _FsoFrameworkAbstractLogger FsoFrameworkAbstractLogger;
typedef struct _FsoFrameworkAbstractLoggerClass FsoFrameworkAbstractLoggerClass;
typedef struct _FsoFrameworkAbstractLoggerPrivate FsoFrameworkAbstractLoggerPrivate;

#define FSO_FRAMEWORK_TYPE_FILE_LOGGER (fso_framework_file_logger_get_type ())
#define FSO_FRAMEWORK_FILE_LOGGER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), FSO_FRAMEWORK_TYPE_FILE_LOGGER, FsoFrameworkFileLogger))
#define FSO_FRAMEWORK_FILE_LOGGER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), FSO_FRAMEWORK_TYPE_FILE_LOGGER, FsoFrameworkFileLoggerClass))
#define FSO_FRAMEWORK_IS_FILE_LOGGER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), FSO_FRAMEWORK_TYPE_FILE_LOGGER))
#define FSO_FRAMEWORK_IS_FILE_LOGGER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), FSO_FRAMEWORK_TYPE_FILE_LOGGER))
#define FSO_FRAMEWORK_FILE_LOGGER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), FSO_FRAMEWORK_TYPE_FILE_LOGGER, FsoFrameworkFileLoggerClass))

typedef struct _FsoFrameworkFileLogger FsoFrameworkFileLogger;
typedef struct _FsoFrameworkFileLoggerClass FsoFrameworkFileLoggerClass;
typedef struct _FsoFrameworkFileLoggerPrivate FsoFrameworkFileLoggerPrivate;

/**
 * AbstractLogger
 */
struct _FsoFrameworkAbstractLogger {
	GObject parent_instance;
	FsoFrameworkAbstractLoggerPrivate * priv;
	guint level;
	char* domain;
	char* destination;
};

struct _FsoFrameworkAbstractLoggerClass {
	GObjectClass parent_class;
	void (*write) (FsoFrameworkAbstractLogger* self, const char* message);
};

/**
 * FileLogger
 */
struct _FsoFrameworkFileLogger {
	FsoFrameworkAbstractLogger parent_instance;
	FsoFrameworkFileLoggerPrivate * priv;
};

struct _FsoFrameworkFileLoggerClass {
	FsoFrameworkAbstractLoggerClass parent_class;
};


void fso_framework_abstract_logger_write (FsoFrameworkAbstractLogger* self, const char* message);
FsoFrameworkAbstractLogger* fso_framework_abstract_logger_construct (GType object_type, const char* domain);
FsoFrameworkAbstractLogger* fso_framework_abstract_logger_new (const char* domain);
void fso_framework_abstract_logger_setLevel (FsoFrameworkAbstractLogger* self, GLogLevelFlags level);
void fso_framework_abstract_logger_setDestination (FsoFrameworkAbstractLogger* self, const char* destination);
void fso_framework_abstract_logger_debug (FsoFrameworkAbstractLogger* self, const char* message);
void fso_framework_abstract_logger_info (FsoFrameworkAbstractLogger* self, const char* message);
void fso_framework_abstract_logger_warning (FsoFrameworkAbstractLogger* self, const char* message);
void fso_framework_abstract_logger_error (FsoFrameworkAbstractLogger* self, const char* message);
GType fso_framework_abstract_logger_get_type (void);
FsoFrameworkFileLogger* fso_framework_file_logger_construct (GType object_type, const char* domain);
FsoFrameworkFileLogger* fso_framework_file_logger_new (const char* domain);
void fso_framework_file_logger_setFile (FsoFrameworkFileLogger* self, const char* filename, gboolean append);
GType fso_framework_file_logger_get_type (void);


G_END_DECLS

#endif
