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


#define FSO_FRAMEWORK_TYPE_LOGGER (fso_framework_logger_get_type ())
#define FSO_FRAMEWORK_LOGGER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), FSO_FRAMEWORK_TYPE_LOGGER, FsoFrameworkLogger))
#define FSO_FRAMEWORK_IS_LOGGER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), FSO_FRAMEWORK_TYPE_LOGGER))
#define FSO_FRAMEWORK_LOGGER_GET_INTERFACE(obj) (G_TYPE_INSTANCE_GET_INTERFACE ((obj), FSO_FRAMEWORK_TYPE_LOGGER, FsoFrameworkLoggerIface))

typedef struct _FsoFrameworkLogger FsoFrameworkLogger;
typedef struct _FsoFrameworkLoggerIface FsoFrameworkLoggerIface;

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

#define FSO_FRAMEWORK_TYPE_SYSLOG_LOGGER (fso_framework_syslog_logger_get_type ())
#define FSO_FRAMEWORK_SYSLOG_LOGGER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), FSO_FRAMEWORK_TYPE_SYSLOG_LOGGER, FsoFrameworkSyslogLogger))
#define FSO_FRAMEWORK_SYSLOG_LOGGER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), FSO_FRAMEWORK_TYPE_SYSLOG_LOGGER, FsoFrameworkSyslogLoggerClass))
#define FSO_FRAMEWORK_IS_SYSLOG_LOGGER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), FSO_FRAMEWORK_TYPE_SYSLOG_LOGGER))
#define FSO_FRAMEWORK_IS_SYSLOG_LOGGER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), FSO_FRAMEWORK_TYPE_SYSLOG_LOGGER))
#define FSO_FRAMEWORK_SYSLOG_LOGGER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), FSO_FRAMEWORK_TYPE_SYSLOG_LOGGER, FsoFrameworkSyslogLoggerClass))

typedef struct _FsoFrameworkSyslogLogger FsoFrameworkSyslogLogger;
typedef struct _FsoFrameworkSyslogLoggerClass FsoFrameworkSyslogLoggerClass;
typedef struct _FsoFrameworkSyslogLoggerPrivate FsoFrameworkSyslogLoggerPrivate;

/**
 * Logger
 */
struct _FsoFrameworkLoggerIface {
	GTypeInterface parent_iface;
	void (*setLevel) (FsoFrameworkLogger* self, GLogLevelFlags level);
	void (*setDestination) (FsoFrameworkLogger* self, const char* destination);
	void (*debug) (FsoFrameworkLogger* self, const char* message);
	void (*info) (FsoFrameworkLogger* self, const char* message);
	void (*warning) (FsoFrameworkLogger* self, const char* message);
	void (*error) (FsoFrameworkLogger* self, const char* message);
};

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
	char* (*format) (FsoFrameworkAbstractLogger* self, const char* message, const char* level);
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

/**
 * SyslogLogger
 */
struct _FsoFrameworkSyslogLogger {
	FsoFrameworkAbstractLogger parent_instance;
	FsoFrameworkSyslogLoggerPrivate * priv;
};

struct _FsoFrameworkSyslogLoggerClass {
	FsoFrameworkAbstractLoggerClass parent_class;
};


void fso_framework_logger_setLevel (FsoFrameworkLogger* self, GLogLevelFlags level);
void fso_framework_logger_setDestination (FsoFrameworkLogger* self, const char* destination);
void fso_framework_logger_debug (FsoFrameworkLogger* self, const char* message);
void fso_framework_logger_info (FsoFrameworkLogger* self, const char* message);
void fso_framework_logger_warning (FsoFrameworkLogger* self, const char* message);
void fso_framework_logger_error (FsoFrameworkLogger* self, const char* message);
GType fso_framework_logger_get_type (void);
void fso_framework_abstract_logger_write (FsoFrameworkAbstractLogger* self, const char* message);
char* fso_framework_abstract_logger_format (FsoFrameworkAbstractLogger* self, const char* message, const char* level);
FsoFrameworkAbstractLogger* fso_framework_abstract_logger_construct (GType object_type, const char* domain);
FsoFrameworkAbstractLogger* fso_framework_abstract_logger_new (const char* domain);
char* fso_framework_abstract_logger_levelToString (GLogLevelFlags level);
GLogLevelFlags fso_framework_abstract_logger_stringToLevel (const char* level);
GType fso_framework_abstract_logger_get_type (void);
FsoFrameworkFileLogger* fso_framework_file_logger_construct (GType object_type, const char* domain);
FsoFrameworkFileLogger* fso_framework_file_logger_new (const char* domain);
void fso_framework_file_logger_setFile (FsoFrameworkFileLogger* self, const char* filename, gboolean append);
GType fso_framework_file_logger_get_type (void);
FsoFrameworkSyslogLogger* fso_framework_syslog_logger_construct (GType object_type, const char* domain);
FsoFrameworkSyslogLogger* fso_framework_syslog_logger_new (const char* domain);
GType fso_framework_syslog_logger_get_type (void);


G_END_DECLS

#endif
