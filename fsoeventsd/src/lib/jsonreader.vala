/*
 * Copyright (C) 2007-2008 Jürg Billeter <j@bitron.ch>
 *               2011 Simon Busch <morphis@gravedo.de>
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
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 *  Jürg Billeter <j@bitron.ch>
 */

using GLib;

public enum FsoEvents.JsonTokenType {
    LEFT_BRACE,
    RIGHT_BRACE,
    LEFT_BRACKET,
    RIGHT_BRACKET,
    STRING,
    STRING_VALUE,
    NUMBER,
    COMMA,
    COLON,
    TRUE,
    FALSE,
    NULL
}

public enum FsoEvents.JsonNodeType {
    START,
    START_OBJECT,
    END_OBJECT,
    START_ARRAY,
    END_ARRAY,
    MEMBER,
    STRING,
    NUMBER,
    TRUE,
    FALSE,
    NULL,
    END
}

public class FsoEvents.JsonReader : GLib.Object {
    public InputStream stream { get; set; }

    private uint8[] buffer;
    private long buffer_pos;
    private long buffer_len;

    private bool current_member_finished = false;

    public string current_string { get; set; }

    private JsonNodeType current_state;
    private Gee.List<int> stack;

    public JsonNodeType node_type {
        get { return current_state; }
    }

    public JsonReader (InputStream stream) {
        this.stream = stream;
    }

    construct {
        buffer = new uint8[512];
        stack = new Gee.ArrayList<int> ();
    }

    private void ensure_buffer (long count) throws IOError {
        assert (count >= 1);

        if (buffer_pos + count <= buffer_len) {
            // buffer already filled
            return;
        }

        if (buffer_pos >= buffer_len) {
            // we don't need current buffer contents anymore
            // refill complete buffer
            buffer_len = stream.read (buffer, null);
            buffer_pos = 0;
            return;
        }

        if (buffer_len > buffer.length / 2) {
            // more than half of the buffer is filled, double buffer size
            buffer.resize (buffer.length * 2);
        }

        // append data to buffer
        buffer_len += stream.read ((uint8[]) ((long) buffer + buffer_len), null);
    }

    private void finish_number (int len) {
        current_string = ((string) ((long) buffer + buffer_pos)).ndup (len);
        buffer_pos += len;
    }

    private void parse_number () throws IOError {
        int state = 0;
        for (int i = 1; true; i++) {
            ensure_buffer (i);
            switch (state) {
            // at start
            case 0:
                switch (buffer[buffer_pos + i - 1]) {
                case '-':
                    state = 1;
                    break;
                case '0':
                    state = 2;
                    break;
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                    state = 3;
                    break;
                default:
                    // throw some exception
                    break;
                }
                break;
            // -
            case 1:
                switch (buffer[buffer_pos + i - 1]) {
                case '0':
                    state = 2;
                    break;
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                    state = 3;
                    break;
                default:
                    // throw some exception
                    break;
                }
                break;
            // -?0
            case 2:
                switch (buffer[buffer_pos + i - 1]) {
                case '.':
                    state = 4;
                    break;
                case 'e':
                case 'E':
                    state = 5;
                    break;
                default:
                    finish_number (i - 1);
                    return;
                }
                break;
            // -?[1-9][0-9]*
            case 3:
                switch (buffer[buffer_pos + i - 1]) {
                case '0':
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                    state = 3;
                    break;
                case '.':
                    state = 4;
                    break;
                default:
                    finish_number (i - 1);
                    return;
                }
                break;
            // -?(0|[1-9][0-9]*)\.
            case 4:
                switch (buffer[buffer_pos + i - 1]) {
                case '0':
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                    state = 6;
                    break;
                default:
                    // throw some exception
                    break;
                }
                break;
            // -?(0|[1-9][0-9]*)(\.[0-9]+)?[eE]
            case 5:
                switch (buffer[buffer_pos + i - 1]) {
                case '0':
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                    state = 7;
                    break;
                case '+':
                case '-':
                    state = 8;
                    break;
                default:
                    // throw some exception
                    break;
                }
                break;
            // -?(0|[1-9][0-9]*)\.[0-9]+
            case 6:
                switch (buffer[buffer_pos + i - 1]) {
                case '0':
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                    state = 6;
                    break;
                case 'e':
                case 'E':
                    state = 5;
                    break;
                default:
                    finish_number (i - 1);
                    return;
                }
                break;
            // -?(0|[1-9][0-9]*)(\.[0-9]+)?[eE](\+|-)?[0-9]+
            case 7:
                switch (buffer[buffer_pos + i - 1]) {
                case '0':
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                    state = 7;
                    break;
                default:
                    finish_number (i - 1);
                    return;
                }
                break;
            // -?(0|[1-9][0-9]*)(\.[0-9]+)?[eE](\+|-)
            case 8:
                switch (buffer[buffer_pos + i - 1]) {
                case '0':
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                    state = 7;
                    break;
                default:
                    // throw some exception
                    break;
                }
                break;
            }
        }
    }

    private void parse_string () throws IOError {
        int i = 1;
        while (true) {
            switch (buffer[buffer_pos + i - 1]) {
            case '\t':
            case '\n':
            case '"':
            case ';':
            case ':':
            case ',':
            case ' ':
                current_string = ((string) ((long) buffer + buffer_pos)).ndup (i - 1);
                if (!current_string.validate ()) {
                    // invalid utf-8
                    current_string = null;
                    // TODO throw some exception
                }
                // FIXME strcompress doesn't handle exactly the same escape sequences
                current_string = current_string.compress ();

                buffer_pos += i - 1;
                return;
            case '\\':
                i++;
                ensure_buffer (i);
                switch (buffer[buffer_pos + i - 1]) {
                case '"':
                case '\\':
                case '/':
                case 'b':
                case 'f':
                case 'n':
                case 'r':
                case 't':
                    break;
                case 'u':
                    i += 4;
                    ensure_buffer (i);
                    // make sure the 4 bytes are valid hex-digits
                    break;
                }
                break;
            default:
                // non-control-character
                break;
            }

            i++;
            ensure_buffer (i);
        }
    }

    private JsonTokenType next_token () throws IOError {
        current_string = null;
        do {
            ensure_buffer (1);

            if ( ((char)buffer[buffer_pos]).isalpha() )
            {
                // stdout.printf(@"maybe string: $((char)buffer[buffer_pos])\n");
                parse_string();
                return JsonTokenType.STRING;
            }

            switch (buffer[buffer_pos]) {
            case ' ':
            case '\t':
            case '\r':
            case '\n':
                // ignore white space
                buffer_pos++;
                break;
            case '"':
                parse_string();
                return JsonTokenType.STRING_VALUE;
            case '{':
                buffer_pos++;
                return JsonTokenType.LEFT_BRACE;
            case '}':
                buffer_pos++;
                return JsonTokenType.RIGHT_BRACE;
            case '[':
                buffer_pos++;
                return JsonTokenType.LEFT_BRACKET;
            case ']':
                buffer_pos++;
                return JsonTokenType.RIGHT_BRACKET;
            case '-':
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
                parse_number ();
                return JsonTokenType.NUMBER;
            case ',':
                buffer_pos++;
                return JsonTokenType.COMMA;
            case ':':
                buffer_pos++;
                return JsonTokenType.COLON;
            case 't':
                ensure_buffer ("true".len ());
                if ((string) ((long) buffer + buffer_pos) != "true") {
                    // TODO throw some exception
                }
                buffer_pos += "true".len ();
                return JsonTokenType.TRUE;
            case 'f':
                ensure_buffer ("false".len ());
                if ((string) ((long) buffer + buffer_pos) != "false") {
                    // TODO throw some exception
                }
                buffer_pos += "false".len ();
                return JsonTokenType.FALSE;
            case 'n':
                ensure_buffer ("null".len ());
                if ((string) ((long) buffer + buffer_pos) != "null") {
                    // TODO throw some exception
                }
                buffer_pos += "true".len ();
                return JsonTokenType.NULL;
            default:
                // TODO throw some exception
                return JsonTokenType.NULL;
            }
        } while (true);

        assert_not_reached ();
    }

    public string enumToString( Type enum_type, int value )
    {
        EnumClass ec = (EnumClass) enum_type.class_ref();
        unowned EnumValue? ev = ec.get_value( value );
        return ev == null ? "Unknown Enum value for %s: %i".printf( enum_type.name(), value ) : ev.value_name;
    }

    private JsonNodeType node_type_for_token(JsonTokenType token)
    {
        var node_type = JsonNodeType.NULL;

        switch (token)
        {
            case JsonTokenType.TRUE:
                node_type = JsonNodeType.TRUE;
                break;
            case JsonTokenType.FALSE:
                node_type = JsonNodeType.FALSE;
                break;
            case JsonTokenType.STRING:
                node_type = JsonNodeType.STRING;
                break;
            case JsonTokenType.NUMBER:
                node_type = JsonNodeType.NUMBER;
                break;
            default:
                break;
        }

        return node_type;
    }

    private bool read_start(JsonTokenType token)
    {
        string previous_string = "";

        if (token == JsonTokenType.STRING)
        {
            previous_string = current_string;

            var token2 = next_token();
            switch (token2)
            {
                case JsonTokenType.LEFT_BRACE:
                    current_state = JsonNodeType.START_OBJECT;
                    current_string = previous_string;
                    break;
                case JsonTokenType.COLON:
                    if (current_state == JsonNodeType.START)
                        return false;

                    current_state = JsonNodeType.STRING;
                    current_string = previous_string;
                    break;
                default:
                    return false;
            }
        }
        else if (current_state != JsonNodeType.START)
        {
            switch (token)
            {
                case JsonTokenType.TRUE:
                case JsonTokenType.FALSE:
                case JsonTokenType.NUMBER:
                    previous_string = current_string;

                    if (next_token() != JsonTokenType.COMMA)
                        return false;

                    current_state = node_type_for_token(token);
                    current_string = previous_string;
                    break;
                case JsonTokenType.LEFT_BRACKET:
                    current_state = JsonNodeType.START_ARRAY;
                    break;
                case JsonTokenType.NULL:
                    current_state = JsonNodeType.NULL;
                    break;
                default:
                    break;
            }
        }

        return true;
    }

    public bool read ()
    {
        string previous_string = "";
        bool result = false;
        var token = next_token();

        switch (current_state)
        {
            case JsonNodeType.START:
                return read_start(token);
                break;
            case JsonNodeType.START_OBJECT:
                switch (token)
                {
                    case JsonTokenType.STRING:
                        current_state = JsonNodeType.MEMBER;
                        result = true;
                        break;
                    case JsonTokenType.RIGHT_BRACE:
                        current_state = JsonNodeType.END_OBJECT;
                        stack.remove_at (stack.size - 1);
                        result = true;
                        break;
                    default:
                        break;
                }
                break;
            case JsonNodeType.MEMBER:
                switch (token)
                {
                    case JsonTokenType.COLON:
                        var token2 = next_token ();
                        result = read_start (token2);
                        break;
                    default:
                        break;
                }
                break;
            case JsonNodeType.END_OBJECT:
            case JsonNodeType.END_ARRAY:
            case JsonNodeType.STRING:
            case JsonNodeType.NUMBER:
            case JsonNodeType.TRUE:
            case JsonNodeType.FALSE:
            case JsonNodeType.NULL:
                if (stack.size == 0)
                {
                    // TODO ensure that we've reached the end of the stream
                    current_state = JsonNodeType.END;
                    break;
                }

                switch (token)
                {
                    case JsonTokenType.STRING:
                        current_state = JsonNodeType.MEMBER;
                        result = true;
                        break;
                    case JsonTokenType.RIGHT_BRACE:
                        current_state = JsonNodeType.END_OBJECT;
                        result = true;
                        break;
                    case JsonTokenType.RIGHT_BRACKET:
                        current_state = JsonNodeType.END_ARRAY;
                        result = true;
                        break;
                    default:
                        break;
                }

                break;
            default:
                break;
        }

        return result;
    }
}
