/*
 * Copyright (C) 2007-2008 Jürg Billeter <j@bitron.ch>
 *               2011-2012 Simon Busch <morphis@gravedo.de>
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
    STRING,
    STRING_VALUE,
    NUMBER,
    COMMA,
    SEMICOLON,
    COLON,
    TRUE,
    FALSE,
    NULL
}

public enum FsoEvents.JsonNodeType {
    START,
    START_OBJECT,
    END_OBJECT,
    MEMBER,
    STRING,
    NUMBER,
    TRUE,
    FALSE,
    NULL,
    END
}

public errordomain FsoEvents.JsonReaderError
{
    INVALID_ENCODING,
    PARSING_ERROR,
}

public class FsoEvents.JsonReader : GLib.Object
{
    public InputStream stream { get; set; }

    private uint8[] buffer;
    private long buffer_pos;
    private long buffer_len;

    private bool current_member_finished = false;

    public string current_string { get; set; }

    private JsonNodeType current_state;
    private Gee.List<int> stack;

    public JsonNodeType node_type
    {
        get { return current_state; }
    }

    public JsonReader (InputStream stream)
    {
        this.stream = stream;
    }

    construct
    {
        buffer = new uint8[512];
        stack = new Gee.ArrayList<int> ();
    }

    private bool ensure_buffer (long count) throws IOError
    {
        assert (count >= 1);

        if (buffer_pos + count <= buffer_len) {
            // buffer already filled
            return true;
        }

        if (buffer_pos >= buffer_len) {
            // we don't need current buffer contents anymore
            // refill complete buffer
            buffer_len = stream.read (buffer, null);
            buffer_pos = 0;
            return buffer_len > 0;
        }

        if (buffer_len > buffer.length / 2)
            // more than half of the buffer is filled, double buffer size
            buffer.resize (buffer.length * 2);

        // append data to buffer
        var bread = stream.read ((uint8[]) ((long) buffer + buffer_len), null);
        buffer_len += bread;
        return bread > 0;
    }

    private void finish_number (int len)
    {
        current_string = ((string) ((long) buffer + buffer_pos)).ndup (len);
        buffer_pos += len;
    }

    private void parse_number () throws IOError
    {
        int state = 0;
        for (int i = 1; true; i++)
        {
            ensure_buffer (i);
            switch (state)
            {
            case 0:
                switch (buffer[buffer_pos + i - 1])
                {
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

    private void parse_string() throws IOError, FsoEvents.JsonReaderError
    {
        int i = 1;
        while (true)
        {
            switch (buffer[buffer_pos + i - 1])
            {
            case '\t':
            case '\n':
            case ' ':
            case ':':
            case ';':
            case '{':
            case '}':
                current_string = ((string) ((long) buffer + buffer_pos)).ndup (i - 1);
                if (!current_string.validate ())
                {
                    current_string = null;
                    throw new FsoEvents.JsonReaderError.INVALID_ENCODING("Input stream contains characters with invalid encoding!");
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
            ensure_buffer(i);
        }
    }

    private void parse_string_value() throws IOError, FsoEvents.JsonReaderError
    {
        int i = 1;
        do
        {
            i++;
            ensure_buffer (i);
            switch (buffer[buffer_pos + i - 1])
            {
            case '"':
                current_string = ((string) ((long) buffer + buffer_pos + 1)).ndup (i - 2);
                if (!current_string.validate ())
                {
                    current_string = null;
                    throw new FsoEvents.JsonReaderError.INVALID_ENCODING("Input stream contains characters with invalid encoding!");
                }
                // FIXME strcompress doesn't handle exactly the same escape sequences
                current_string = current_string.compress ();
                buffer_pos += i;
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
        } while (true);
    }

    private JsonTokenType next_token () throws IOError, FsoEvents.JsonReaderError {
        current_string = "";
        do
        {
            if (!ensure_buffer(1))
            {
                return JsonTokenType.NULL;
            }

            if ( ((char)buffer[buffer_pos]).isalpha() )
            {
                parse_string();

                if (current_string == "true")
                    return JsonTokenType.TRUE;
                else if (current_string == "false")
                    return JsonTokenType.FALSE;
                else if (current_string == "null")
                    return JsonTokenType.NULL;

                return JsonTokenType.STRING;
            }

            switch (buffer[buffer_pos]) {
            case ' ':
            case '\t':
            case '\r':
            case '\n':
                buffer_pos++;
                break;
            case '"':
                parse_string_value();
                return JsonTokenType.STRING_VALUE;
            case '{':
                buffer_pos++;
                return JsonTokenType.LEFT_BRACE;
            case '}':
                buffer_pos++;
                return JsonTokenType.RIGHT_BRACE;
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
            case ';':
                buffer_pos++;
                return JsonTokenType.SEMICOLON;
            case ':':
                buffer_pos++;
                return JsonTokenType.COLON;
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

    public bool read() throws FsoEvents.JsonReaderError
    {
        var token = next_token ();

        stdout.printf(@"current token = $(token), current_string = $(current_string), current_state = $(current_state)\n");

        switch (current_state)
        {
            case JsonNodeType.START:
                return read_start (token);

            case JsonNodeType.START_OBJECT:
                switch (token)
                {
                    case JsonTokenType.STRING:
                        current_state = JsonNodeType.MEMBER;
                        return true;
                    case JsonTokenType.RIGHT_BRACE:
                        current_state = JsonNodeType.END_OBJECT;
                        stack.remove_at (stack.size - 1);
                        return true;
                    default:
                        // throw some exception
                        return false;
                }
            case JsonNodeType.END_OBJECT:
            case JsonNodeType.STRING:
            case JsonNodeType.NUMBER:
            case JsonNodeType.TRUE:
            case JsonNodeType.FALSE:
            case JsonNodeType.NULL:
                if (stack.size == 0)
                {
                    // TODO ensure that we've reached the end of the stream
                    current_state = JsonNodeType.END;
                    return false;
                }
                var prev_state = stack.get (stack.size - 1);
                switch (prev_state)
                {
                    case JsonNodeType.START_OBJECT:
                        switch (token)
                        {
                            case JsonTokenType.SEMICOLON:
                                var token2 = next_token ();
                                switch (token2)
                                {
                                    case JsonTokenType.STRING:
                                        current_state = JsonNodeType.MEMBER;
                                        return true;
                                    case JsonTokenType.RIGHT_BRACE:
                                        current_state = JsonNodeType.END_OBJECT;
                                        stack.remove_at(stack.size - 1);
                                        return true;
                                    default:
                                        var msg = @"Got wrong token $token in state $current_state";
                                        throw new FsoEvents.JsonReaderError.PARSING_ERROR(msg);
                                    }
                                current_state = JsonNodeType.MEMBER;
                                return true;
                            case JsonTokenType.RIGHT_BRACE:
                                current_state = JsonNodeType.END_OBJECT;
                                stack.remove_at (stack.size - 1);
                                return true;
                            default:
                                // throw some exception
                                return false;
                        }
                    default:
                        // throw some exception
                        return false;
                }
            case JsonNodeType.MEMBER:
                switch (token)
                {
                    case JsonTokenType.COLON:
                        var token2 = next_token ();
                        return read_start (token2);
                    default:
                        // throw some exception
                        return false;
                }
            case JsonNodeType.END:
                return false;
            default:
                // throw some exception
                return false;
        }
    }

    private bool read_start (JsonTokenType token) throws FsoEvents.JsonReaderError
    {
        stdout.printf(@"read_start with token = $(token), current_string = $(current_string == null ? "" : current_string)\n");

        switch (token)
        {
        case JsonTokenType.STRING_VALUE:
            current_state = JsonNodeType.STRING;
            return true;
        case JsonTokenType.STRING:
            var previous_string = current_string;

            var token2 = next_token();
            if (token2 != JsonTokenType.LEFT_BRACE)
            {
                var msg = @"Got wrong token $token in state $current_state";
                throw new FsoEvents.JsonReaderError.PARSING_ERROR(msg);
            }

            current_state = JsonNodeType.START_OBJECT;
            current_string = previous_string;
            stack.add((int) current_state);
            return true;
        case JsonTokenType.NUMBER:
            current_state = JsonNodeType.NUMBER;
            return true;
        case JsonTokenType.TRUE:
            current_state = JsonNodeType.TRUE;
            return true;
        case JsonTokenType.FALSE:
            current_state = JsonNodeType.FALSE;
            return true;
        case JsonTokenType.NULL:
            current_state = JsonNodeType.NULL;
            return true;
        default:
            var msg = @"Got wrong token $token in state $current_state";
            throw new FsoEvents.JsonReaderError.PARSING_ERROR(msg);
            break;
        }
        return false;
    }
}
