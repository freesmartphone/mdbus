/*
 * Copyright (C) 2012 Simon Busch <morphis@gravedo.de>
 *
 * This is a Vala adoption of the GAtResultIter class implementation
 * from the ofono project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */

namespace FsoGsm
{
    private const int AT_RESULT_LINE_LENGTH_MAX = 2048;

    public class AtResultIter
    {
        private int _line_pos;
        private int _line_num;
        private string[] _lines;
        private string _line;

        //
        // private API
        //

        private int skip_to_next_field( string line, int pos )
        {
            if ( pos < line.length && line[pos] == ',' )
                pos++;

            while ( pos < line.length && line[pos] == ' ' )
                pos++;

            return pos;
        }

        private int skip_until( string line, int start, char delim )
        {
            int len = line.length;
            int i = start;

            while ( i < len )
            {
                if ( line[i] == delim )
                    return i;

                if ( line[i] == '\"' )
                {
                    i += 1;
                    while ( i < len && line[i] != '\"' )
                        i++;

                    if ( i < len )
                        i++;

                    continue;
                }

                if ( line[i] != '(' )
                {
                    i++;
                    continue;
                }

                i = skip_until( line, i + 1, ')' );

                if ( i < len )
                    i++;
            }

            return i;
        }

        //
        // public API
        //

        public AtResultIter( string[] lines )
        {
            _lines = lines;
            _line_pos = 0;
            _line_num = 0;
            _line = "";
        }

        public bool next( string prefix )
        {
            string line = "";
            bool result = false;

            for ( ; _line_num < _lines.length; _line_num++ )
            {
                line = _lines[_line_num];

                if ( line.length > AT_RESULT_LINE_LENGTH_MAX )
                {
                    _line_num++;
                    continue;
                }

                if ( prefix.length == 0 )
                {
                    _line_pos = 0;
                    break;
                }

                if ( line.has_prefix( prefix ) )
                {
                    _line_pos = prefix.length;

                    while ( _line_pos < line.length &&
                            line[_line_pos] == ' ' )
                        _line_pos++;

                    break;
                }
            }

            if ( _line_num < _lines.length )
            {
                _line = line.dup();
                result = true;

                if ( _line_num == _lines.length - 1 )
                    _line_num = _lines.length;
            }
            else
            {
                _line = "";
                _line_pos = 0;
            }

            return result;
        }

        public bool next_number( out int number )
        {
            int end = _line_pos;
            int value = 0;

            while ( _line[end] >= '0' && _line[end] <= '9' )
            {
                value = value * 10 + (int) (_line[end] - '0');
                end++;
            }

            if ( _line_pos == end )
                return false;

            _line_pos = skip_to_next_field( _line, end );
            number = value;

            return true;
        }

        public bool next_string( out string str )
        {
            int end;
            int pos;

            pos = _line_pos;

            if ( _line[pos] == ',')
            {
                end = pos;
                str =  "";
            }
            else
            {
                if ( _line[pos++] != '"' )
                    return false;

                end = pos;
                while ( end < _line.length && _line[end] != '"' )
                    end++;

                if ( _line[end] != '"' )
                    return false;

                end++;

                str = _line.substring( _line_pos, end - _line_pos );
            }

            _line_pos = skip_to_next_field( _line, end );

            return true;
        }

        public bool next_unquoted_string( out string str )
        {
            int end;
            int pos;

            pos = _line_pos;

            if ( _line[pos] == ',')
            {
                end = pos;
                str =  "";
            }
            else
            {
                if ( _line[pos] == '"' || _line[pos] == ')' )
                    return false;

                end = pos;

                while ( end < _line.length && _line[end] != ',' && _line[end] != ')' )
                    end++;

                str = _line.substring( _line_pos, end - _line_pos );
            }

            _line_pos = skip_to_next_field( _line, end );

            return true;
        }

        public bool skip_next()
        {
            var skipped_to = skip_until( _line, _line_pos, ',' );

            if ( skipped_to == _line_pos && _line[skipped_to] != ',' )
                return false;

            _line_pos = skip_to_next_field( _line, skipped_to );
            return true;
        }

        public bool open_list()
        {
            int len = _line.length;

            if ( _line_pos >= len )
                return false;

            if ( _line[_line_pos] != '(' )
                return false;

            _line_pos++;

            while ( _line_pos < len && _line[_line_pos] == ' ' )
                _line_pos++;

            return true;
        }

        public bool close_list()
        {
            int len = _line.length;

            if ( _line_pos >= len )
                return false;

            if ( _line[_line_pos] != ')' )
                return false;

            _line_pos++;
            _line_pos = skip_to_next_field( _line, _line_pos );

            return true;
        }

    }
}

// vim:ts=4:sw=4:expandtab
