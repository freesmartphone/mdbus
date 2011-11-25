#ifndef LIBCMTSPEECHDATA_H_
#define LIBCMTSPEECHDATA_H_

#include <time.h>

typedef struct {
    unsigned short msec;
    unsigned short usec;
    struct timespec tstamp;
} CmtSpeechTimingConfigNtf;

typedef struct {
    unsigned char layout;
    unsigned char version;
    unsigned char result;
} CmtSpeechSsiConfigResp;

typedef struct {
    unsigned char speech_data_stream;
    unsigned char call_user_connect_ind;
    unsigned char codec_info;
    unsigned char cellular_info;
    unsigned char sample_rate;
    unsigned char data_format;
    unsigned char layout_changed;
} CmtSpeechSpeechConfigReq;

typedef struct {
    CmtSpeechSsiConfigResp ssi_config_resp;
    CmtSpeechSpeechConfigReq speech_config_resp;
    CmtSpeechTimingConfigNtf timing_config_ntf;
} CmtSpeechEventData;

#endif

