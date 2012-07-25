/*
 * Authored by Frederik 'playya' Sdun <Frederik.Sdun@googlemail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 */
using GLib;
namespace FsoFramework {

/*TODO:
 * insert/set pad
 * set pad
 * more tests
 */
public class BinBuilder: Object
{
    public static uint8 nth_byte(uint64 val, uint byte)
    {
        if( byte > sizeof(uint64) )
        {
            critical(@"byte value out of range: $byte");
            return 0;
        }
        return (uint8)((val >> (byte * 8)) & 0xFF);
    }

    protected List<uint8> _data;
    public uint8[] data{
        get {
            uint8[] result = new uint8[_data.length()];
            int i = 0;
            foreach(var e in _data)
                    result[i++] = e;
            return result[0:-1];
        }
    }
    public uint length {
        get {
            return _data.length();
        }
    }

    public GLib.DataStreamByteOrder endianess {get;set;}
    public uint alignment {get;set;default=0;}
    public uint8 alignment_byte{get;set;default='\0';}

    public bool packed {
        get {
            return alignment == 0;
        }
    }

    public class BinBuilder(int alignment = 0, uint8 alignment_byte = '\0', GLib.DataStreamByteOrder e = GLib.DataStreamByteOrder.HOST_ENDIAN)
    {
        endianess = e;
        this.alignment = alignment;
        this.alignment_byte = alignment_byte;
    }

    construct
    {
        _data = new List<uint8>();
    }

    public void append_string(string s, bool include_null_byte = true, int pad_to = 0, uint8 padding = '\0')
    {
        _data.reverse();
        foreach(var i in s.data)
                _data.prepend(i);

        if(include_null_byte)
             _data.prepend('\0');

        _data.reverse();

        append_pad(pad_to - s.length - (include_null_byte ? 1 : 0), padding);

        append_align();
    }

    public void append_data(uint8[] d, int pad_to = 0, uint8 padding = '\0')
    {
        _data.reverse();
        foreach(var e in d)
        {
            _data.prepend(e);
        }
        _data.reverse();
        append_pad(pad_to - d.length, padding);
        append_align();
    }

    public void append_uint8(uint8 c)
    {
        _data.append( c );
        append_align();
    }

    public void append_int8(int8 c)
    {
        _data.append( (uint8)c );
        append_align();
    }

    public void append_uint16(uint16 v)
    {
        v = uint16_convert(v);

        _data.append( nth_byte(v,1) );
        _data.append( nth_byte(v,0) );

        append_align();
    }

    public void append_int16(int16 v)
    {
        var uv = uint16_convert((uint16)v);

        _data.append( nth_byte(uv,1) );
        _data.append( nth_byte(uv,0) );

        append_align();
    }

    public void append_uint32(uint32 v)
    {
        v = uint32_convert(v);
        _data.reverse();

        for(int i = 0; i < 4; i ++)
            _data.prepend( nth_byte(v,i) );

        _data.reverse();

        append_align();
    }

    public void append_int32(int32 v)
    {
        var uv = uint32_convert((uint32)v);
        _data.reverse();

        for(int i = 0; i < 4; i ++)
            _data.prepend( nth_byte(uv,i) );

        _data.reverse();

        append_align();
    }

    public void append_uint64(uint64 v)
    {
        v = uint64_convert(v);
        _data.reverse();

        for(int i = 0; i < 8; i ++)
            _data.prepend( nth_byte(v,i) );

        _data.reverse();

        append_align();
    }

    public void append_int64(int64 v)
    {
        var uv = uint64_convert((uint64)v);
        _data.reverse();

        for(int i = 0; i < 8; i ++)
            _data.prepend( nth_byte(uv,i) );

        _data.reverse();

        append_align();
    }

    public void append_custom(uint64 val, int size)
    {
        for(int i = size - 1; i >=0; i-- )
        {
            _data.append( nth_byte(val,i) );
        }
        append_align();
    }

    public void append_pad(long length, uint8 byte)
    {
        if(length > 0)
        {
            _data.reverse();

            for(int i = 0; i < length; i++)
                _data.prepend( byte );

            _data.reverse();
        }
    }

    public void append_align()
    {
        if(alignment == 0)
             return;
        var align_bytes = alignment - (_data.length() % alignment);

        if(align_bytes != alignment)
        {
            for(int i = 0; i < align_bytes; i++)
            {
                _data.append( alignment_byte );
            }
        }
    }

    public void append_crc16(int start = 0, int end = -1)
    {
        append_uint16(Checksum.crc16(data[start:end]));
    }

    public void append_bitfield(int position, uint64 value, int offset = 0, int bit_length = 1, int byte_length = 1)
    {
        int x = 0;
        unowned List<uint8> l = get_at(position, byte_length);
        for(int i = offset; i < offset + length; i ++)
        {
            bool v = ((value & (1 << x)) == 0 ) ? true : false;
            set_bit(ref l.nth(position + offset / 8).data, offset % 8, v);
            x ++;
        }
    }
    public void set_uint8(uint8 val, int position)
    {
        unowned List<uint8> l = null;

        if(position < 0 )
        {
             _data.prepend(val);
             return;
        }
        l = get_at(position);

        l.data = val;
    }

    public void set_uint16(uint16 val, int position)
    {
        unowned List<uint8> l = get_at(position, 2);
        int i = 0;

        for(i = 1; i <= 2; i ++)
        {
            l.data = nth_byte(val, 2 - i);
            l = l.next;
        }
    }

    public void set_uint32(uint32 val, int position)
    {
        unowned List<uint8> l = get_at(position, 4);
        int i = 0;

        for(i = 1; i <= 4 && l != null; i ++)
        {
            l.data = nth_byte(val, 4 - i);
            l = l.next;
        }
    }

    public void set_uint64(uint64 val, int position)
    {
        unowned List<uint8> l = get_at(position, 8);
        int i = 0;

        for(i = 1; i <= 8 && l != null; i ++)
        {
            l.data = nth_byte(val, 8 - i);
            l = l.next;
        }
    }

    public void set_string(string s, int position, bool include_null_byte = true, uint pad_to = 0, uint8 padding = '\0')
    {
        var string_len = s.length;

        if(position < 0)
             position += (int) _data.length();

        unowned List<uint8> l = get_at(position, (uint)((pad_to == 0) ? (string_len + (include_null_byte ? 1 : 0)) : pad_to));
        foreach(var e in s.data)
        {
            l.data = e;
            l = l.next;
        }
        for(int i = (int)s.length; i < pad_to; i ++)
        {
            l.data = padding;
            l = l.next;
        }
    }

    public new void set_data(uint8[] d, int position, uint pad_to = 0, uint8 padding = '\0')
    {
        unowned List<uint8> l = get_at(position, data.length);
        foreach(var e in d)
        {
            l.data = e;
            l = l.next;
        }
    }

    public void set_align(int pos)
    {
        if(pos < 0)
             pos += (int)_data.length();
        var nr_bytes = alignment - pos % alignment;

        if(nr_bytes == 0 || nr_bytes == alignment)
             return;

        unowned List<uint8> l = get_at(pos, nr_bytes);
        for(int i = 0; i < nr_bytes; i++)
        {
            l.data = alignment_byte;
            l = l.next;
        }
    }

    public void set_crc16(int pos, int start = 0, int end = -1)
    {
        set_uint16(Checksum.crc16(data[start:end]), pos);
    }

    public void insert_uint8(uint8 val, int position)
    {
        unowned List<uint16> l = get_at(position);
        l.insert(val, position);
    }

    public void insert_uint16(uint16 val, int position)
    {
        unowned List<uint8> l = get_at(position);
        val = uint16_convert(val);
        l.insert(nth_byte(val, 0), 0);
        l.insert(nth_byte(val, 1), 1);
    }

    public void insert_uint32(uint32 val, int position)
    {
        unowned List<uint8> l = get_at(position);
        val = uint32_convert(val);
        for(int i = 0; i < 4; i ++)
            l.insert(nth_byte(val, i), i);
    }

    public void insert_uint64(uint64 val, int position)
    {
        unowned List<uint8> l = get_at(position);
        val = uint64_convert(val);
        for(int i = 0; i < 8; i ++)
            l.insert(nth_byte(val, i), i);
    }

    public void insert_string(string str, int position)
    {
        unowned List<uint8> l = get_at(position);
        int i = 0;
        foreach(var s in str.data)
            l.insert(s, i++);
    }

    public void insert_data(uint8[] data, int position)
    {
        unowned List<uint8> l = get_at(position);
        int i = 0;
        foreach(var d in data)
            l.insert(d, i++);
    }

    public void insert_crc16(int pos, int start = 0, int end = -1)
    {
        insert_uint16(Checksum.crc16(data[start:end]), pos);
    }

    public void reset()
    {
        _data = new List<uint8>();
    }

    public uint16 uint16_convert(uint16 val)
    {
        if(endianess == GLib.DataStreamByteOrder.BIG_ENDIAN)
            return val.to_big_endian();
        else if(endianess == GLib.DataStreamByteOrder.LITTLE_ENDIAN)
            return val.to_little_endian();
        else
             return val;
    }

    public uint32 uint32_convert(uint32 val)
    {
        if(endianess == GLib.DataStreamByteOrder.BIG_ENDIAN)
            return val.to_big_endian();
        else if(endianess == GLib.DataStreamByteOrder.LITTLE_ENDIAN)
            return val.to_little_endian();
        else
             return val;
    }

    public uint64 uint64_convert(uint64 val)
    {
        if(endianess == GLib.DataStreamByteOrder.BIG_ENDIAN)
            return val.to_big_endian();
        else if(endianess == GLib.DataStreamByteOrder.LITTLE_ENDIAN)
            return val.to_little_endian();
        else
             return val;
    }

    protected unowned List<uint8> get_at(int position, uint assure_nth = 1)
    {
        if(position < 0)
             position += (int)_data.length();
        else if(position + assure_nth > (_data.length()))
        {
            append_pad(position - _data.length() + assure_nth, alignment_byte);
        }
        return _data.nth(position);
    }
    internal static void set_bit(ref uint8 data, int bit, bool value)
    {
        bit = 8 - bit - 1;
        data |= ((uint8)value << bit);
    }
}

public class BinReader : Object
{
        private uint8[] data;

        public int alignment{get;set;default=0;}
        public bool packed {get{return alignment == 0;}}
        public GLib.DataStreamByteOrder endianess;

        public BinReader( uint8[] d, int alignment = 0, GLib.DataStreamByteOrder e = GLib.DataStreamByteOrder.HOST_ENDIAN )
        {
            data = d;
            this.alignment = alignment;
            endianess = e;
        }

        public BinReader.void_pointer( void* d, uint len, int alignment = 0, GLib.DataStreamByteOrder e = GLib.DataStreamByteOrder.HOST_ENDIAN )
        {
            data = new uint8[len];
            Posix.memcpy( data, d, len);
            this.alignment = alignment;
            endianess = e;
        }

        public uint8 get_uint8(int pos) throws BinReaderError
        {
            var off = offset( sizeof(uint8) );
            pos = absolute_position( pos, off + (int)sizeof(uint8) );
            return data[pos + off];
        }

        public uint16 get_uint16( int pos ) throws BinReaderError
        {
            uint16 result = 0;
            var off = offset( sizeof(uint16) );
            pos = absolute_position( pos, off + (int)sizeof(uint16) );
            result = ((uint16)data[pos + off]) << 8;
            result |= ((uint16)data[pos + off + 1]);

            return uint16_convert(result);
        }

        public uint32 get_uint32( int pos ) throws BinReaderError
        {
            uint32 result = 0;
            var off = offset( sizeof(uint32) );
            pos = absolute_position( pos, off + (int)sizeof(uint32) );
            result =  ((uint32)data[pos + off]) << 24;
            result |= ((uint32)data[pos + off + 1]) << 16;
            result |= ((uint32)data[pos + off + 2]) << 8;
            result |= ((uint32)data[pos + off + 3]);

            return uint32_convert(result);
        }

        public uint64 get_uint64( int pos ) throws BinReaderError
        {
            uint64 result = 0;
            var off = offset( sizeof(uint64) );

            pos = absolute_position( pos, off + (int)sizeof(uint64) );
            result = ((uint64)data[pos + off]) << 56;
            result |= ((uint64)data[pos + off + 1]) << 48;
            result |= ((uint64)data[pos + off + 2]) << 40;
            result |= ((uint64)data[pos + off + 3]) << 32;
            result |= ((uint64)data[pos + off + 4]) << 24;
            result |= ((uint64)data[pos + off + 5]) << 16;
            result |= ((uint64)data[pos + off + 6]) << 8;
            result |= ((uint64)data[pos + off + 7]);

            return uint64_convert(result);
        }

        public string get_string(int pos, int length = -1) throws BinReaderError
        {
            pos = absolute_position(pos, 0);
            unowned string result = ((string)data).offset(pos);
            if(length >= 0)
                 return result.ndup(length);
            else
                 return result.dup();
        }

        public new uint8[] get_data(int pos, int length) throws BinReaderError
        {
            pos = absolute_position(pos, length);
            return data[pos:pos+length];
        }

        public bool crc16_verify(int crc_position, int start = 0, int end = -3) throws BinReaderError
        {
            uint16 sum = 0;
            uint8[] data = new uint8[0];

            if(crc_position > start && crc_position < end)
                 throw new BinReaderError.CHECKSUM_IN_DATA(@"Checksum at $crc_position is within data range [$start:$end]");
            try
            {
                sum = get_uint16(crc_position);
            }
            catch (GLib.Error e)
            {
                throw new BinReaderError.OUT_OF_RANGE(@"CRC position[$crc_position] is out of range $(data.length)" );
            }

            try
            {
                data = get_data(start, end - start);
            }
            catch (GLib.Error e)
            {
                throw new BinReaderError.OUT_OF_RANGE(@"Data out of range [$(data.length)]");
            }

            return Checksum.crc16_verify(data, sum);
        }

        public uint64 get_bits(int position, int offset, int length) throws BinReaderError
        {
            uint64 result = 0;
            //int byte_offset = offset / 8;

            if(length > 64)
                 throw new BinReaderError.ILLEGAL_PARAMETER(@"length[$length] is > 64");

            position = absolute_position(position, offset/8 + length/8);

            for(int i = position * 8 + offset; i < position * 8 + offset + length; i ++)
            {
                result <<= 1;
                result |= get_bit(data[i/8], i % 8);
            }

            return result;
        }

        public uint16 uint16_convert( uint16 val )
        {
            if(endianess == GLib.DataStreamByteOrder.BIG_ENDIAN)
                 return uint16.from_big_endian(val);
            else if(endianess == GLib.DataStreamByteOrder.LITTLE_ENDIAN)
                 return uint16.from_little_endian(val);
            else
                 return val;
        }

        public uint32 uint32_convert( uint32 val )
        {
            if(endianess == GLib.DataStreamByteOrder.BIG_ENDIAN)
                 return uint32.from_big_endian(val);
            else if(endianess == GLib.DataStreamByteOrder.LITTLE_ENDIAN)
                 return uint32.from_little_endian(val);
            else
                 return val;
        }

        public uint64 uint64_convert(uint64 val)
        {
            if(endianess == GLib.DataStreamByteOrder.BIG_ENDIAN)
                 return uint64.from_big_endian(val);
            else if(endianess == GLib.DataStreamByteOrder.LITTLE_ENDIAN)
                 return uint64.from_little_endian(val);
            else
                 return val;
        }

        private int absolute_position(int pos, int num_bytes = 0) throws BinReaderError
        {
            int result = pos;

            if( result < 0 )
                 result += data.length;

            if(alignment != 0)
            {
                 result -= (result % alignment);
            }

            if( result < 0 || (result + num_bytes) > data.length )
                 throw new BinReaderError.OUT_OF_RANGE(@"$pos with is out of range for $(data.length)");

            return result;
        }

        private int offset( size_t type_size )
        {
            int result = 0;
            if( endianess == DataStreamByteOrder.LITTLE_ENDIAN && ! packed )
                 result = alignment - ((int)type_size) % alignment;

            return result == alignment ? 0 : result;
        }

        internal static uint8 get_bit(uint8 data, int bit)
        {
            bit = 8 - bit - 1;
            return (uint8)((data & (1 << bit)) >> bit) & 0x1;
        }
}

public errordomain BinReaderError
{
    OUT_OF_RANGE,
    CHECKSUM_IN_DATA,
    ILLEGAL_PARAMETER
}
}

// vim:ts=4:sw=4:expandtab
