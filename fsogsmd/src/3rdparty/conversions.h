#ifndef CONVERSIONS_H
#define CONVERSIONS_H

char *utf8_to_ucs2(const char* str);
char *utf8_to_gsm(const char* str);
char *gsm_to_utf8(const char* str);
char *ucs2_to_utf8(const char *str);
typedef struct sms structsms;
void sms_copy(void* self, void* dup);
struct sms* sms_new();
void sms_free(struct sms* self);
long sms_size();
struct cbs* cbs_new();
void cbs_free(struct cb* self);

#endif /* CONVERSIONS_H */


