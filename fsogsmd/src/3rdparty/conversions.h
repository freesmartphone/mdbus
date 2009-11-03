#ifndef CONVERSIONS_H
#define CONVERSIONS_H

char *ucs2_to_utf8(const char *str);
typedef struct sms structsms;
struct sms* sms_new();
void sms_free(struct sms* self);
long sms_size();

#endif /* CONVERSIONS_H */


