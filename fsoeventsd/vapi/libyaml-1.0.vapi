/* ************
 *
 * Copyright (C) 2009  Denis Tereshkin
 * Copyright (C) 2009  Dmitriy Kuteynikov
 * Copyright (C) 2009  Yu Feng
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
 * License along with this library; if not, write to 
 *
 * the Free Software Foundation, Inc., 
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Denis Tereshkin
 * 	Dmitriy Kuteynikov <kuteynikov@gmail.com>
 * 	Yu Feng <rainwoodman@gmail.com>
 ***/

[CCode (cprefix="YAML", cheader_filename="yaml.h", lower_case_cprefix="yaml_")]
namespace YAML {

	public const string DEFAULT_SCALAR_TAG;
	public const string DEFAULT_SEQUENCE_TAG;
	public const string DEFAULT_MAPPING_TAG;
	public const string NULL_TAG;
	public const string BOOL_TAG;
	public const string STR_TAG;
	public const string INT_TAG;
	public const string FLOAT_TAG;
	public const string TIMESTAMP_TAG;
	public const string SEQ_TAG;
	public const string MAP_TAG;

	[CCode (cprefix="YAML_", cname="yaml_node_type_t", has_type_id=false)]
	public enum NodeType {
		NO_NODE,
		SCALAR_NODE,
		SEQUENCE_NODE,
		MAPPING_NODE
	}
	[CCode (cprefix="YAML_", cname="yaml_scalar_style_t", has_type_id=false)]
	public enum ScalarStyle {
		ANY_SCALAR_STYLE,
		PLAIN_SCALAR_STYLE,
		SINGLE_QUOTED_SCALAR_STYLE,
		DOUBLE_QUOTED_SCALAR_STYLE,
		LITERAL_SCALAR_STYLE,
		FOLDED_SCALAR_STYLE
	}

	[CCode (cprefix="YAML_", cname="yaml_sequence_style_t", has_type_id=false)]
	/** 
	 * Sequence styles 
	 * */
	public enum SequenceStyle{
		ANY_SEQUENCE_STYLE ,
		BLOCK_SEQUENCE_STYLE,
		FLOW_SEQUENCE_STYLE
	}
	/** 
	 * Mapping styles. 
	 * */
	[CCode (cprefix="YAML_", cname="yaml_mapping_style_t", has_type_id=false)]
	public enum MappingStyle {
		ANY_MAPPING_STYLE,
		BLOCK_MAPPING_STYLE,
		FLOW_MAPPING_STYLE
	}

	/** 
	 * The version directive data. 
	 * */
	[CCode (cname="yaml_version_directive_t", has_type_id = false)]
	public struct VersionDirective {
		public int major;
		public int minor;
	}

	/** 
	 * The tag directive data. 
	 * */
	[CCode (cname = "yaml_tag_directive_t", has_type_id = false)]
	public struct TagDirective {
		public string handle;
		public string prefix;
	}
	/** Line break types. */

	[CCode (cprefix="YAML_", cname="yaml_break_t", has_type_id=false)]
	public enum BreakType {
		ANY_BREAK,
		CR_BREAK,
		LN_BREAK,
		CRLN_BREAK
	}

	[CCode (cname="yaml_mark_t", has_type_id = false)]
	/** 
	 * The pointer position. 
	 * */
	public struct Mark {
		public size_t index;
		public size_t line;
		public size_t column;
		public string to_string() {
			return "index:%u line:%u column:%u".printf(
				(uint)index, (uint)line, (uint)column);
		}
	}

	[CCode (cname = "yaml_event_type_t", cprefix="YAML_", has_type_id = false)]
	public enum EventType {
		NO_EVENT,

		STREAM_START_EVENT,
		STREAM_END_EVENT,

		DOCUMENT_START_EVENT,
		DOCUMENT_END_EVENT,

		ALIAS_EVENT,
		SCALAR_EVENT,

		SEQUENCE_START_EVENT,
		SEQUENCE_END_EVENT,

		MAPPING_START_EVENT,
		MAPPING_END_EVENT
	}

	[CCode (has_type_id = false)]
	public struct EventAlias {
		public string anchor;
	}

	[CCode (has_type_id = false)]
	public struct EventSequenceStart {
		public string anchor;
		public string tag;
		public int implicity;
		public YAML.SequenceStyle style;
	}

	[CCode (has_type_id = false)]
	public struct EventMappingStart {
		public string anchor;
		public string tag;
		public int implicity;
		public YAML.MappingStyle style;
	}

	/** 
	 * The scalar parameters (for @c YAML_SCALAR_EVENT). 
	 * */
	[CCode (has_type_id = false)]
	public struct EventScalar {
		/* The anchor. */
		public string anchor;
		/* The tag. */
		public string tag;
		/* The scalar value. */
		public string value;
		/* The length of the scalar value. */
		public size_t length;
		/* Is the tag optional for the plain style? */
		public int plain_implicit;
		/* Is the tag optional for any non-plain style? */
		public int quoted_implicit;
		public ScalarStyle style;
	}

	[CCode (has_type_id=false)]
	public struct EventData {
		public YAML.EventAlias alias;
		public YAML.EventScalar scalar;
		public YAML.EventSequenceStart sequence_start;
		public YAML.EventMappingStart mapping_start;
	}

	[CCode (has_type_id = false,
			cname="yaml_event_t", 
			lower_case_cprefix="yaml_event_",
			destroy_function="yaml_event_delete")]
	public struct Event {
		[CCode (cname="yaml_stream_start_event_initialize")]
		public static int stream_start_initialize(ref YAML.Event event, YAML.EncodingType encoding);

		[CCode (cname="yaml_stream_end_event_initialize")]
		public static int stream_end_initialize(ref YAML.Event event);

		[CCode (cname="yaml_document_start_event_initialize")]
		public static int document_start_initialize(ref YAML.Event event, void* version_directive = null, void* tag_directive_start = null, void* tag_directive_end = null,
		                            bool implicit = true);

		[CCode (cname="yaml_document_end_event_initialize")]
		public static int document_end_initialize(ref YAML.Event event, bool implicit = true);

		[CCode (cname="yaml_alias_event_initialize")]
		public static int alias_initialize(ref YAML.Event event, string anchor);

		[CCode (cname="yaml_scalar_event_initialize")]
		public static int scalar_initialize(ref YAML.Event event, string? anchor, string? tag, string value, int length, 
		                   bool plain_implicit = true, bool quoted_implicity = true, 
		                   YAML.ScalarStyle style = YAML.ScalarStyle.ANY_SCALAR_STYLE );

		[CCode (cname="yaml_sequence_start_event_initialize")]
		public static int sequence_start_initialize(ref YAML.Event event, string? anchor = null, string? tag = null, bool implicit = true, YAML.SequenceStyle style = YAML.SequenceStyle.ANY_SEQUENCE_STYLE);
		[CCode (cname="yaml_sequence_end_event_initialize")]
		public static int sequence_end_initialize(ref YAML.Event event);

		[CCode (cname="yaml_mapping_start_event_initialize")]
		public static int mapping_start_initialize(ref YAML.Event event, string? anchor = null, string? tag = null, bool implicit = true, YAML.MappingStyle style = YAML.MappingStyle.ANY_MAPPING_STYLE);
		[CCode (cname="yaml_mapping_end_event_initialize")]
		public static int mapping_end_initialize(ref YAML.Event event);

		public static void clean(ref YAML.Event event) {
			event.type = YAML.EventType.NO_EVENT;
		}
		public EventType type;
		public YAML.EventData data;
		public Mark start_mark;
		public Mark end_mark;

	}

	/** 
	 * The stream encoding. 
	 * */
	[CCode (cname = "yaml_encoding_t", cprefix="YAML_", has_type_id = false)]
	public enum EncodingType {
		/* Let the parser choose the encoding. */
		ANY_ENCODING,
		/* The default UTF-8 encoding. */
		UTF8_ENCODING,
		/* The UTF-16-LE encoding with BOM. */
		UTF16LE_ENCODING,
		/* The UTF-16-BE encoding with BOM. */
		UTF16BE_ENCODING
	}

	/** Many bad things could happen with the parser and emitter. */
	[CCode (cname="yaml_error_type_t", prefix="YAML_", has_type_id=false)]
	public enum ErrorType {
		NO_ERROR,

		/* Cannot allocate or reallocate a block of memory. */
		MEMORY_ERROR,

		/* Cannot read or decode the input stream. */
		READER_ERROR,
		/* Cannot scan the input stream. */
		SCANNER_ERROR,
		/* Cannot parse the input stream. */
		PARSER_ERROR,
		/* Cannot compose a YAML document. */
		COMPOSER_ERROR,

		/* Cannot write to the output stream. */
		WRITER_ERROR,
		/* Cannot emit a YAML stream. */
		EMITTER_ERROR
	}

	[CCode (has_type_id = false,
			cname="yaml_parser_t", 
			lower_case_cprefix="yaml_parser_", 
			destroy_function="yaml_parser_delete")]
	public struct Parser {
		public YAML.ErrorType error;
		public string problem;
		public size_t problem_offset;
		public int problem_value;
		public YAML.Mark problem_mark;
		public string context;
		public YAML.Mark context_mark;

		public bool stream_start_produced;
		public bool stream_end_produced;
		[CCode (cname="yaml_parser_initialize")]
		public Parser();

		/*
		 * Set the input to a string.
		 *
		 * libyaml doesn't take an ownership reference of the string.
		 * Make sure you keep the string alive during the lifetime of
		 * the parser!
		 *
		 * size is in bytes, not in characters. Use string.size() to obtain
		 * the size.
		 * */
		public void set_input_string(string input, size_t size);
		/*
		 * Set the input to a file stream.
		 *
		 * libyaml doesn't take an ownership reference of the stream.
		 * Make sure you keep the stream alive during the lifetime of
		 * the parser!
		 * */
		public void set_input_file(GLib.FileStream file);
		public void set_encoding(YAML.EncodingType encoding);
		public bool parse(out YAML.Event event);
	}

	[CCode (instance_pos = 0, cname="yaml_write_handler_t")]
	public delegate int WriteHandler(char[] buffer);

	[CCode (has_type_id = false,
			cname="yaml_emitter_t", 
			lower_case_cprefix="yaml_emitter_", 
			destroy_function="yaml_emitter_delete")]
	public struct Emitter {
		[CCode (cname="yaml_emitter_initialize")]
		public Emitter();
		/*
		 * Set the output to a string.
		 *
		 * libyaml doesn't take an ownership reference of the string.
		 * Make sure you keep the string alive during the lifetime of
		 * the emitter!
		 *
		 * size is in bytes, not in characters. Use string.size() to obtain
		 * the size.
		 * */
		public void set_output_string(char[] input, out size_t written);
		/*
		 * Set the output to a file stream.
		 *
		 * libyaml doesn't take an ownership reference of the stream.
		 * Make sure you keep the stream alive during the lifetime of
		 * the emitter!
		 * */
		public void set_output_file(GLib.FileStream file);

		public void set_output(YAML.WriteHandler handler);

		public void set_encoding(YAML.EncodingType encoding);
		public void set_canonical(bool canonical);
		public void set_indent(int indent);
		public void set_width(int width);
		public void set_unicode(bool unicode);
		public void set_break(YAML.BreakType break);
		public int emit(ref YAML.Event event);
		public int flush();
	}

}
