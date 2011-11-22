/**
 *
 * Copyright (C) 2009  Denis Tereshkin
 * Copyright (C) 2009  Dmitriy Kuteynikov
 * Copyright (C) 2009  Yu Feng
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
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
 *  Denis Tereshkin
 *  Dmitriy Kuteynikov <kuteynikov@gmail.com>
 *  Yu Feng <rainwoodman@gmail.com>
 ***/

[CCode (cprefix="YAML", cheader_filename="yaml.h", lower_case_cprefix="yaml_")]
namespace Yaml
{
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
    public enum NodeType
    {
        NO_NODE,
        SCALAR_NODE,
        SEQUENCE_NODE,
        MAPPING_NODE
    }

    [CCode (cprefix="YAML_", cname="yaml_scalar_style_t", has_type_id=false)]
    public enum ScalarStyle
    {
        ANY_SCALAR_STYLE,
        PLAIN_SCALAR_STYLE,
        SINGLE_QUOTED_SCALAR_STYLE,
        DOUBLE_QUOTED_SCALAR_STYLE,
        LITERAL_SCALAR_STYLE,
        FOLDED_SCALAR_STYLE
    }

    /**
     * Sequence styles
     * */
    [CCode (cprefix="YAML_", cname="yaml_sequence_style_t", has_type_id=false)]
    public enum SequenceStyle
    {
        ANY_SEQUENCE_STYLE ,
        BLOCK_SEQUENCE_STYLE,
        FLOW_SEQUENCE_STYLE
    }

    /**
     * Mapping styles.
     * */
    [CCode (cprefix="YAML_", cname="yaml_mapping_style_t", has_type_id=false)]
    public enum MappingStyle
    {
        ANY_MAPPING_STYLE,
        BLOCK_MAPPING_STYLE,
        FLOW_MAPPING_STYLE
    }

    /** 
     * The version directive data
     * */
    [CCode (cname="yaml_version_directive_t", has_type_id = false)]
    public struct VersionDirective
    {
        public int major;
        public int minor;
    }

    /** 
     * The tag directive data
     * */
    [CCode (cname = "yaml_tag_directive_t", has_type_id = false)]
    public struct TagDirective
    {
        public string handle;
        public string prefix;
    }

    /**
     * Line break types
     **/
    [CCode (cprefix="YAML_", cname="yaml_break_t", has_type_id=false)]
    public enum BreakType
    {
        ANY_BREAK,
        CR_BREAK,
        LN_BREAK,
        CRLN_BREAK
    }


    /**
     * The pointer position.
     * */
    [CCode (cname="yaml_mark_t", has_type_id = false)]
    public struct Mark
    {
        public size_t index;
        public size_t line;
        public size_t column;

        public string to_string()
        {
            return "index:%u line:%u column:%u".printf((uint)index, (uint)line, (uint)column);
        }
    }

    [CCode (cname = "yaml_event_type_t", cprefix="YAML_", has_type_id = false)]
    public enum EventType
    {
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

    public string event_type_to_string(EventType type)
    {
        string result = "UNKNOWN";

        switch (type)
        {
            case EventType.NO_EVENT:
                result = "NO_EVENT";
                break;
            case EventType.STREAM_START_EVENT:
                result = "STREAM_START_EVENT";
                break;
            case EventType.STREAM_END_EVENT:
                result = "STREAM_END_EVENT";
                break;
            case EventType.DOCUMENT_START_EVENT:
                result = "DOCUMENT_START_EVENT";
                break;
            case EventType.DOCUMENT_END_EVENT:
                result = "DOCUMENT_END_EVENT";
                break;
            case EventType.ALIAS_EVENT:
                result = "ALIAS_EVENT";
                break;
            case EventType.SCALAR_EVENT:
                result = "SCALAR_EVENT";
                break;
            case EventType.SEQUENCE_START_EVENT:
                result = "SEQUENCE_START_EVENT";
                break;
            case EventType.SEQUENCE_END_EVENT:
                result = "SEQUENCE_END_EVENT";
                break;
            case EventType.MAPPING_START_EVENT:
                result = "MAPPING_START_EVENT";
                break;
            case EventType.MAPPING_END_EVENT:
                result = "MAPPING_END_EVENT";
                break;
            default:
                break;
        }

        return result;
    }

    [CCode (has_type_id = false)]
    public struct EventAlias
    {
        public string anchor;
    }

    [CCode (has_type_id = false)]
    public struct EventSequenceStart
    {
        public string anchor;
        public string tag;
        public int implicity;
        public Yaml.SequenceStyle style;
    }

    [CCode (has_type_id = false)]
    public struct EventMappingStart
    {
        public string anchor;
        public string tag;
        public int implicity;
        public Yaml.MappingStyle style;
    }

    /** 
     * The scalar parameters (for @c YAML_SCALAR_EVENT).
     * */
    [CCode (has_type_id = false)]
    public struct EventScalar
    {
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
    public struct EventData
    {
        public Yaml.EventAlias alias;
        public Yaml.EventScalar scalar;
        public Yaml.EventSequenceStart sequence_start;
        public Yaml.EventMappingStart mapping_start;
    }

    [CCode (has_type_id = false, cname="yaml_event_t", lower_case_cprefix="yaml_event_", destroy_function="yaml_event_delete")]
    public struct Event
    {
        [CCode (cname="yaml_stream_start_event_initialize")]
        public static int stream_start_initialize(ref Yaml.Event event, Yaml.EncodingType encoding);

        [CCode (cname="yaml_stream_end_event_initialize")]
        public static int stream_end_initialize(ref Yaml.Event event);

        [CCode (cname="yaml_document_start_event_initialize")]
        public static int document_start_initialize(ref Yaml.Event event, void* version_directive = null,
            void* tag_directive_start = null, void* tag_directive_end = null, bool implicit = true);

        [CCode (cname="yaml_document_end_event_initialize")]
        public static int document_end_initialize(ref Yaml.Event event, bool implicit = true);

        [CCode (cname="yaml_alias_event_initialize")]
        public static int alias_initialize(ref Yaml.Event event, string anchor);

        [CCode (cname="yaml_scalar_event_initialize")]
        public static int scalar_initialize(ref Yaml.Event event, string? anchor, string? tag, string value, int length,
                           bool plain_implicit = true, bool quoted_implicity = true,
                           Yaml.ScalarStyle style = Yaml.ScalarStyle.ANY_SCALAR_STYLE );

        [CCode (cname="yaml_sequence_start_event_initialize")]
        public static int sequence_start_initialize(ref Yaml.Event event, string? anchor = null,
            string? tag = null, bool implicit = true, Yaml.SequenceStyle style = Yaml.SequenceStyle.ANY_SEQUENCE_STYLE);

        [CCode (cname="yaml_sequence_end_event_initialize")]
        public static int sequence_end_initialize(ref Yaml.Event event);

        [CCode (cname="yaml_mapping_start_event_initialize")]
        public static int mapping_start_initialize(ref Yaml.Event event, string? anchor = null, 
            string? tag = null, bool implicit = true, Yaml.MappingStyle style = Yaml.MappingStyle.ANY_MAPPING_STYLE);

        [CCode (cname="yaml_mapping_end_event_initialize")]
        public static int mapping_end_initialize(ref Yaml.Event event);

        public static void clean(ref Yaml.Event event)
        {
            event.type = Yaml.EventType.NO_EVENT;
        }

        public EventType type;
        public Yaml.EventData data;
        public Mark start_mark;
        public Mark end_mark;

    }

    /** 
     * The stream encoding.
     * */
    [CCode (cname = "yaml_encoding_t", cprefix="YAML_", has_type_id = false)]
    public enum EncodingType
    {
        /* Let the parser choose the encoding. */
        ANY_ENCODING,
        /* The default UTF-8 encoding. */
        UTF8_ENCODING,
        /* The UTF-16-LE encoding with BOM. */
        UTF16LE_ENCODING,
        /* The UTF-16-BE encoding with BOM. */
        UTF16BE_ENCODING
    }

    [CCode (cname="yaml_error_type_t", prefix="YAML_", has_type_id=false)]
    public enum ErrorType
    {
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

    [CCode (has_type_id = false, cname="yaml_parser_t", lower_case_cprefix="yaml_parser_", destroy_function="yaml_parser_delete")]
    public struct Parser
    {
        public Yaml.ErrorType error;
        public string problem;
        public size_t problem_offset;
        public int problem_value;
        public Yaml.Mark problem_mark;
        public string context;
        public Yaml.Mark context_mark;

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
        public void set_encoding(Yaml.EncodingType encoding);
        public bool parse(out Yaml.Event event);
    }

    [CCode (instance_pos = 0, cname="yaml_write_handler_t")]
    public delegate int WriteHandler(char[] buffer);

    [CCode (has_type_id = false, cname="yaml_emitter_t", lower_case_cprefix="yaml_emitter_", destroy_function="yaml_emitter_delete")]
    public struct Emitter
    {
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

        public void set_output(Yaml.WriteHandler handler);

        public void set_encoding(Yaml.EncodingType encoding);
        public void set_canonical(bool canonical);
        public void set_indent(int indent);
        public void set_width(int width);
        public void set_unicode(bool unicode);
        public void set_break(Yaml.BreakType break);
        public int emit(ref Yaml.Event event);
        public int flush();
    }
}
