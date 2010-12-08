/*
 * Copyright (C) 2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 */

namespace Linux
{
    [CCode (cprefix = "", lower_case_cprefix = "i2c_")]
    namespace I2C
    {
        [CCode (cprefix = "", lower_case_cprefix = "i2c_smbus_")]
        namespace SMBUS
        {
            //[CCode (cheader_filename = "linux/i2c-dev.h")]
            //int32 access(int file, char read_write, uint8 command, int size, union data *data);
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 write_quick(int file, uint8 value);
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 read_byte(int file);
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 write_byte(int file, uint8 value);
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 read_byte_data(int file, uint8 command);
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 write_byte_data(int file, uint8 command, uint8 value);
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 read_word_data(int file, uint8 command);
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 write_word_data(int file, uint8 command, uint16 value); 
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 process_call(int file, uint8 command, uint16 value);
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 read_block_data(int file, uint8 command, [CCode (array_length=false)] uint8[] values);
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 write_block_data([CCode (array_length_pos = 2.9)] int file, uint8 command, uint8[] values); 
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 read_i2c_block_data([CCode (array_length_pos = 2.9)] int file, uint8 command, uint8[] values);
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 write_i2c_block_data([CCode (array_length_pos = 2.9)] int file, uint8 command, uint8[] values);
            [CCode (cheader_filename = "linux/i2c-dev.h")]
            int32 block_process_call([CCode (array_length_pos = 2.9)] int file, uint8 command, uint8[] values);
        }
    }
}
