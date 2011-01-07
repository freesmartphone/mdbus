/* 
 * File Name: 
 * Creation Date: 
 * Last Modified: 
 *
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

struct uint8TestData
{
    uint8[] data;
    uint8 expected;
    int alignment;
    int offset;
    bool expect_exception;
    DataStreamByteOrder endianess;
    string name;
    public uint8TestData(uint8[] d, uint8 exp, int align, int off, bool exceptions, DataStreamByteOrder e, string n)
    {
        data = d;
        expected = exp;
        alignment = align;
        offset = off;
        expect_exception = exceptions;
        endianess = e;
        name = n;
    }
}

void test_uint8(uint8TestData[] datas)
{
    foreach(var data in datas)
    {
        uint8 result = 0;
        var reader = new FsoFramework.BinReader(data.data, data.alignment, data.endianess);
        bool caught = false;
        try
        {
            result = reader.get_uint8(data.offset);
        }
        catch(FsoFramework.BinReaderError e)
        {
            if(!data.expect_exception)
                 error(@"[$(data.name)] doesn't expect an exception: $(e.message)");
            caught = true;
        }
        if(!data.expect_exception)
            named_assert_uint8(data.name, result, data.expected);
        else if(!data.expect_exception && ! caught)
             error(@"[$(data.name)] expected exception");
    }
}

inline void named_assert_uint8(string name, uint8 expected, uint8 result)
{
        if(expected != result)
             error(@"[$name] $result != $expected");
}

void test_uint8_le()
{
    uint8TestData[] tests = {
            uint8TestData( { 0, 0, 0, 42 }, 42, 4, 0, false, DataStreamByteOrder.LITTLE_ENDIAN, "0 offset" ),
            uint8TestData( { 0, 0, 0, 0, 0, 0, 0, 42 }, 42, 4, 4, false, DataStreamByteOrder.LITTLE_ENDIAN, "4 offset" ),
            uint8TestData( { 0, 0, 0, 0, 0, 0, 0, 42 }, 42, 4, 5, false, DataStreamByteOrder.LITTLE_ENDIAN, "5 offset" )
    };
    test_uint8(tests);
}

void test_uint8_be()
{
    uint8TestData[] tests = {
            uint8TestData( { 42, 0, 0, 0 }, 42, 4, 0, false, DataStreamByteOrder.BIG_ENDIAN, "0 offset" ),
            uint8TestData( { 0, 0, 0, 0, 42, 0, 0, 0 }, 42, 4, 4, false, DataStreamByteOrder.BIG_ENDIAN, "4 offset" )
    };
    test_uint8(tests);

}

void test_exception_uint8()
{
    uint8TestData[] tests = {
        uint8TestData( { 0, 0, 0 }, 0, 4, 0, true, DataStreamByteOrder.LITTLE_ENDIAN, "0 offset exception"),
        uint8TestData( { 0, 0, 0, 0, 0, 0, 0 }, 0, 4, 4, true, DataStreamByteOrder.LITTLE_ENDIAN, "4 offset exception")
    };
    test_uint8(tests);
}

struct uint16TestData
{
    uint8[] data;
    uint16 expected;
    int alignment;
    int offset;
    bool expect_exception;
    DataStreamByteOrder endianess;
    string name;
    public uint16TestData(uint8[] d, uint16 exp, int align, int off, bool exceptions, DataStreamByteOrder e, string n)
    {
        data = d;
        expected = exp;
        alignment = align;
        offset = off;
        expect_exception = exceptions;
        endianess = e;
        name = n;
    }
}

void test_uint16(uint16TestData[] datas)
{
    foreach(var data in datas)
    {
        uint16 result = 0;
        var reader = new FsoFramework.BinReader(data.data, data.alignment, data.endianess);
        bool caught = false;
        try
        {
            result = reader.get_uint16(data.offset);
        }
        catch(FsoFramework.BinReaderError e)
        {
            if(!data.expect_exception)
                 error(@"[$(data.name)] doesn't expect an exception: $(e.message)");
            caught = true;
        }
        if(!data.expect_exception)
            named_assert_uint16(data.name, result, data.expected);
        else if( data.expect_exception && ! caught )
             error(@"[$(data.name)] expected exception");
    }
}

inline void named_assert_uint16(string name, uint16 expected, uint16 result)
{
        if(expected != result)
             error(@"[$name] result [$result] != expected [$expected]");
}

void test_uint16_le()
{
    uint16TestData[] tests = {
        uint16TestData({ 0, 0, 0x11, 0x22 }, 0x1122, 4, 0, false, DataStreamByteOrder.LITTLE_ENDIAN, "0 offset 4 byte alignment"),
        uint16TestData({ 0, 0, 0, 0, 0, 0, 0x11, 0x22 }, 0x1122, 4, 4, false, DataStreamByteOrder.LITTLE_ENDIAN, "4 offset 4 byte alignment"),
        uint16TestData({ 0x11, 0x22 }, 0x1122, 2, 0, false, DataStreamByteOrder.LITTLE_ENDIAN, "0 offset 2 byte alignment"),
        uint16TestData({ 0, 0, 0x11, 0x22 }, 0x1122, 2, 2, false, DataStreamByteOrder.LITTLE_ENDIAN, "2 offset 2 byte alignment")
    };

    test_uint16(tests);
}

void test_uint16_be()
{
    uint16TestData[] tests = {
        uint16TestData({ 0x22, 0x11, 0, 0 }, 0x1122, 4, 0, false, DataStreamByteOrder.BIG_ENDIAN, "0 offset 4 byte alignment"),
        uint16TestData({ 0, 0, 0, 0, 0x22, 0x11, 0, 0 }, 0x1122, 4, 4, false, DataStreamByteOrder.BIG_ENDIAN, "4 offset 4 byte alignment"),
        uint16TestData({ 0x22, 0x11 }, 0x1122, 2, 0, false, DataStreamByteOrder.BIG_ENDIAN, "0 offset 2 byte alignment"),
        uint16TestData({ 0, 0, 0x22, 0x11 }, 0x1122, 2, 2, false, DataStreamByteOrder.BIG_ENDIAN, "2 offset 2 byte alignment")
    };

    test_uint16(tests);
}

void test_exception_uint16()
{
    uint16TestData[] tests = {
        uint16TestData( new uint8[5], 0x1122, 2, 4, true, DataStreamByteOrder.BIG_ENDIAN, "5 byte 4 bytes alignment 4 offset"),
        uint16TestData( new uint8[1], 0x1122, 2, 0, true, DataStreamByteOrder.BIG_ENDIAN, "1 byte 2 bytes alignment"),
        uint16TestData( new uint8[1], 0x1122, 0, 0, true, DataStreamByteOrder.BIG_ENDIAN, "1 byte no alignment")
    };

    test_uint16(tests);
}

struct uint32TestData
{
    uint8[] data;
    uint32 expected;
    int alignment;
    int offset;
    bool expect_exception;
    DataStreamByteOrder endianess;
    string name;
    public uint32TestData(uint8[] d, uint32 exp, int align, int off, bool exceptions, DataStreamByteOrder e, string n)
    {
        data = d;
        expected = exp;
        alignment = align;
        offset = off;
        expect_exception = exceptions;
        endianess = e;
        name = n;
    }
}

void test_uint32(uint32TestData[] datas)
{
    foreach(var data in datas)
    {
        uint32 result = 0;
        var reader = new FsoFramework.BinReader(data.data, data.alignment, data.endianess);
        bool caught = false;
        try
        {
            result = reader.get_uint32(data.offset);
        }
        catch(FsoFramework.BinReaderError e)
        {
            if(!data.expect_exception)
                 error(@"[$(data.name)] doesn't expect an exception: $(e.message)");
            caught = true;
        }
        if(!data.expect_exception)
            named_assert_uint32(data.name, result, data.expected);
        else if( data.expect_exception && ! caught)
            error(@"[$(data.name)] expected exception");
    }
}

inline void named_assert_uint32(string name, uint32 expected, uint32 result)
{
        if(expected != result)
             error(@"[$name] result [$result] != expected [$expected]");
}

void test_uint32_be()
{
    uint32TestData[] tests = {
        uint32TestData( { 0x44, 0x33, 0x22, 0x11 }, 0x11223344, 4, 0, false, DataStreamByteOrder.BIG_ENDIAN, "0 offset 4 bytes alignment"),
        uint32TestData( { 0, 0, 0, 0, 0x44, 0x33, 0x22, 0x11 }, 0x11223344, 4, 4, false, DataStreamByteOrder.BIG_ENDIAN, "4 offset 4 bytes alignment"),
        uint32TestData( { 0x44, 0x33, 0x22, 0x11 }, 0x11223344, 2, 0, false, DataStreamByteOrder.BIG_ENDIAN, "0 offset 2 bytes alignment"),
        uint32TestData( { 0, 0, 0x44, 0x33, 0x22, 0x11 }, 0x11223344, 2, 3, false, DataStreamByteOrder.BIG_ENDIAN, "3 offset 2 bytes alignment"),
        uint32TestData( { 0, 0, 0, 0, 0, 0x44, 0x33, 0x22, 0x11 }, 0x11223344, 0, 5, false, DataStreamByteOrder.BIG_ENDIAN, "5 offset packed")
    };

    test_uint32(tests);
}

void test_uint32_le()
{
    uint32TestData[] tests = {
        uint32TestData( { 0x11, 0x22, 0x33, 0x44 }, 0x11223344, 4, 0, false, DataStreamByteOrder.LITTLE_ENDIAN, "0 offset 4 bytes alignment"),
        uint32TestData( { 0, 0, 0, 0, 0x11, 0x22, 0x33, 0x44  }, 0x11223344, 4, 4, false, DataStreamByteOrder.LITTLE_ENDIAN, "4 offset 4 bytes alignment"),
        uint32TestData( { 0x11, 0x22, 0x33, 0x44 }, 0x11223344, 2, 0, false, DataStreamByteOrder.LITTLE_ENDIAN, "0 offset 2 bytes alignment"),
        uint32TestData( { 0, 0, 0x11, 0x22, 0x33, 0x44 }, 0x11223344, 2, 3, false, DataStreamByteOrder.LITTLE_ENDIAN, "3 offset 2 bytes alignment"),
        uint32TestData( { 0, 0, 0, 0, 0, 0x11, 0x22, 0x33, 0x44 }, 0x11223344, 0, 5, false, DataStreamByteOrder.LITTLE_ENDIAN, "5 offset packed")
    };

    test_uint32(tests);
}

void test_exception_uint32()
{
    uint32TestData[] tests = {
        uint32TestData( new uint8[3], 0, 4, 0, true, DataStreamByteOrder.HOST_ENDIAN, "3bytes 0 offset"),
        uint32TestData( new uint8[7], 0, 4, 4, true, DataStreamByteOrder.HOST_ENDIAN, "7bytes 4 offset"),
        uint32TestData( new uint8[8], 0, 0, 5, true, DataStreamByteOrder.HOST_ENDIAN, "8bytes 5 offset packet"),
        uint32TestData( new uint8[5], 0, 2, 2, true, DataStreamByteOrder.HOST_ENDIAN, "5bytes 0 offset 2 bytes alignment")
    };
    test_uint32(tests);
}

struct stringTestData
{
        uint8[] data;
        int alignment;
        string expected;
        bool expect_exception;
        string name;
        int offset;
        int length;
        public stringTestData(uint8[] d, int a, string e, bool exc, string n, int o, int l)
        {
            data = d;
            alignment = a;
            expected = e;
            expect_exception = exc;
            name = n;
            offset = o;
            length = l;
        }
}

inline void named_assert_string(string name, string expected, string result)
{
        if(expected != result)
             error(@"[$name] result [$result] != expected [$expected]");
}

void test_string(stringTestData[] datas)
{
    foreach(var data in datas)
    {
        var reader = new FsoFramework.BinReader(data.data);
        bool caught = false;
        string result = "";
        try
        {
            result = reader.get_string(data.offset, data.length);
        }
        catch(FsoFramework.BinReaderError e)
        {
            if( !data.expect_exception )
                 error(@"[$(data.name)] doesn't expect an exception: $(e.message)");
            caught = true;
        }
        if(!data.expect_exception)
            named_assert_string(data.name, data.expected, result);
        else if( data.expect_exception && ! caught)
            error(@"[$(data.name)] expected exception");
    }
}

void test_strings()
{
    stringTestData[] tests = {
        stringTestData({ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'H', 'A', 'L', 'L', 'O', ' ', 'W', 'E', 'L', 'T', 0 }, 4, "HALLO WELT", false, "string @12", 12, -1),
        stringTestData({ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'H', 'A', 'L', 'L', 'O', ' ', 'W', 'E', 'L', 'T', 0 }, 0, "HALLO WELT", false, "string @10 packed", 10, -1),
        stringTestData({ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'H', 'A', 'L', 'L', 'O', ' ', 'W', 'E', 'L', 'T', 0 }, 0, "HALLO", false, "string @10 packed limit 5", 10, 5),
        stringTestData({ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'H', 'A', 'L', 'L', 'O', ' ', 'W', 'E', 'L', 'T', 0 }, 0, "", false, "string @20 empty packed", 20, 5),
        stringTestData({ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'H', 'A', 'L', 'L', 'O', ' ', 'W', 'E', 'L', 'T', 0 }, 0, "", false, "string @10 0 length packed", 10, 0)
    };

    test_string(tests);
}

struct dataTestData
{
        uint8[] data;
        int alignment;
        uint8[] expected;
        bool expect_exception;
        string name;
        int offset;
        int length;
        public dataTestData(uint8[] d, int a, uint8[] e, bool exc, string n, int o, int l)
        {
            data = d;
            alignment = a;
            expected = e;
            expect_exception = exc;
            name = n;
            offset = o;
            length = l;
        }
}

inline void named_assert_data(string name, uint8[] expected, uint8[] result)
{
        if(!uint8_array_equal(expected, result))
             error(@"[$name] result [$(uint8_array_to_string(result))] != expected [$(uint8_array_to_string(expected))]");
}

string uint8_array_to_string(uint8[] data)
{
    string result = "";
    foreach(var d in data)
        result += "'%02X', ".printf(d);
    return result;
}

bool uint8_array_equal(uint8[] a, uint8[] b)
{
    if(a.length != b.length)
         return false;
    for(int i = 0; i < a.length; i++)
    {
        if(a[i] != b[i])
             return false;
    }
    return true;
}

void test_data(dataTestData[] datas)
{
    foreach(var data in datas)
    {
        var reader = new FsoFramework.BinReader(data.data);
        bool caught = false;
        uint8[] result = new uint8[0];
        try
        {
            result = reader.get_data(data.offset, data.length);
        }
        catch(FsoFramework.BinReaderError e)
        {
            if( !data.expect_exception )
                 error(@"[$(data.name)] doesn't expect an exception: $(e.message)");
            caught = true;
        }
        if(!data.expect_exception)
            named_assert_data(data.name, data.expected, result);
        else if( data.expect_exception && ! caught)
            error(@"[$(data.name)] expected exception");
    }
}

void test_datas()
{
    dataTestData[] tests = {
        dataTestData({}, 4, {}, false, "empty", 0, 0),
        dataTestData({ 0, 1, 2, 3 }, 4, { 0, 1, 2, 3 }, false, "full", 0, 4),
        dataTestData({ 0, 0, 0, 0, 0, 1, 2, 3 }, 4, { 0, 1, 2, 3 }, false, "full offset 4", 4, 4),
        dataTestData({ 0, 1, 2, 3 , 0, 0, 0, 0}, 4, { 0, 1, 2, 3 }, false, "full", 0, 4)
    };
    test_data(tests);
}


void main(string[] args)
{
    Test.init(ref args);

    Test.add_func("/FsoFramework.BinReader/String", test_strings);
    Test.add_func("/FsoFramework.BinReader/Data", test_datas);
    Test.add_func("/FsoFramework.BinReader/LittleEndian/uint8", test_uint8_le);
    Test.add_func("/FsoFramework.BinReader/LittleEndian/uint16", test_uint16_le);
    Test.add_func("/FsoFramework.BinReader/LittleEndian/uint32", test_uint32_le);
    Test.add_func("/FsoFramework.BinReader/BigEndian/uint8", test_uint8_be);
    Test.add_func("/FsoFramework.BinReader/BigEndian/uint16", test_uint16_be);
    Test.add_func("/FsoFramework.BinReader/BigEndian/uint32", test_uint32_be);
    Test.add_func("/FsoFramework.BinReader/Exception/uint8", test_exception_uint8);
    Test.add_func("/FsoFramework.BinReader/Exception/uint16", test_exception_uint16);
    Test.add_func("/FsoFramework.BinReader/Exception/uint32", test_exception_uint32);

    Test.run();
}
