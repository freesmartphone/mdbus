/*
 * Copyright (C) 2011 Simon Busch <morphis@gravedo.de>
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
 */

namespace FsoEvents
{
    public errordomain RulesParserError
    {
        INVALID_INPUT_FILE,
        INVALID_FILE_FORMAT,
        INVALID_OBJECT,
        INTERNAL_ERROR,
    }

    public class RulesParser : FsoFramework.AbstractObject
    {
        private JsonReader reader;
        private string filename;

        construct
        {
            typeof(AndFilter);
            typeof(OrFilter);
        }

        public RulesParser.from_path(string path)
        {
            this.filename = path;
        }

        public Gee.ArrayList<Rule> read() throws RulesParserError
        {
            var rules = new Gee.ArrayList<Rule>();

            var file = GLib.File.new_for_path(filename);
            // FIXME check if file is valid
            var stream = file.read(null);
            reader = new JsonReader(stream);

            try
            {
                while (reader.read())
                {
                    if (reader.node_type == JsonNodeType.END)
                    {
                        break;
                    }
                    else if (reader.node_type != JsonNodeType.START_OBJECT)
                    {
                        var msg = @"Got invalid node $(reader.node_type) while "
                                  + "searching for a new rule";
                        throw new RulesParserError.INVALID_FILE_FORMAT(msg);
                    }

                    assert(logger.debug(@"Parsing a new rule ..."));
                    parse_rule();
                }
            }
            catch (JsonReaderError error)
            {
                var msg = @"Could not parse file $filename: $(error.message)";
                throw new RulesParserError.INVALID_FILE_FORMAT(msg);
            }

            return rules;
        }

        private void parse_rule() throws RulesParserError, JsonReaderError
        {
            var rule = new Rule();

            while (reader.read())
            {
                if (reader.node_type == JsonNodeType.END_OBJECT)
                {
                    break;
                }
                else if (reader.node_type == JsonNodeType.MEMBER)
                {
                    if (reader.current_string == "trigger")
                    {
                        rule.trigger = parse_trigger();
                    }
                    else if (reader.current_string == "filter")
                    {
                        rule.filter = parse_filter();
                    }
                    else if (reader.current_string == "name")
                    {
                        rule.name = parse_string();
                    }
                    else
                    {
                        var msg = @"Got invalid member \"$(reader.current_string)\" "
                                  + "while parsing a new rule";
                        throw new RulesParserError.INVALID_FILE_FORMAT(msg);
                    }
                }
                else
                {
                    var msg = @"Got invalid node $(reader.node_type) while "
                              + "parsing a new rule";
                    throw new RulesParserError.INVALID_FILE_FORMAT(msg);

                }
            }
        }

        private string parse_string() throws RulesParserError, JsonReaderError
        {
            if (!reader.read())
            {
                var msg = @"Reader returned false when it should not!";
                throw new RulesParserError.INTERNAL_ERROR(msg);
            }

            if (reader.node_type != JsonNodeType.STRING)
            {
                var msg = @"Got node $(reader.node_type) when expecting "
                          + "$(JsonNodeType.STRING)";
                throw new RulesParserError.INVALID_FILE_FORMAT(msg);
            }

            return reader.current_string;
        }

        private BaseFilter create_filter(string typename)
        {
            BaseFilter filter = null;

            switch (typename)
            {
                case "And":
                    filter = new AndFilter();
                    break;
                case "Or":
                    filter = new OrFilter();
                    break;
                default:
                    break;
            }

            return filter;
        }

        private BaseFilter parse_filter() throws RulesParserError, JsonReaderError
        {
            BaseFilter filter = null;
            string filter_name = "unknown";

            while (reader.read())
            {
                if (filter == null)
                {
                    if (reader.node_type == JsonNodeType.START_OBJECT)
                    {
                        filter = create_filter(reader.current_string);
                        if (filter == null)
                        {
                            var msg = @"Could not create instance of object $(reader.current_string)";
                            throw new RulesParserError.INVALID_OBJECT(msg);
                        }
                    }
                    else
                    {
                        var msg = @"Got wrong node type $(reader.node_type) when "
                                  + "expecting $(JsonNodeType.START_OBJECT)";
                        throw new RulesParserError.INVALID_FILE_FORMAT(msg);
                    }
                }
                else
                {
                    if (reader.node_type == JsonNodeType.END_OBJECT)
                    {
                        break;
                    }
                    if (reader.node_type == JsonNodeType.MEMBER)
                    {
                        // FIXME how to handle properties of a filter?
                    }
                }
            }

            return filter;
        }

        private BaseTrigger parse_trigger() throws RulesParserError, JsonReaderError
        {
            BaseTrigger trigger = null;

            return trigger;
        }

        public override string repr()
        {
            return @"<>";
        }
    }
}
