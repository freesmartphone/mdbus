/* Copyright (C) 2008 The Android Open Source Project
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h>
#include <stdint.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

#include <linux/ioctl.h>

#if 0
#include <linux/msm_audio.h>
#else
/* ---------- linux/msm_audio.h -------- */

#define AUDIO_IOCTL_MAGIC 'a'

#define AUDIO_START        _IOW(AUDIO_IOCTL_MAGIC, 0, unsigned)
#define AUDIO_STOP         _IOW(AUDIO_IOCTL_MAGIC, 1, unsigned)
#define AUDIO_FLUSH        _IOW(AUDIO_IOCTL_MAGIC, 2, unsigned)
#define AUDIO_GET_CONFIG   _IOR(AUDIO_IOCTL_MAGIC, 3, unsigned)
#define AUDIO_SET_CONFIG   _IOW(AUDIO_IOCTL_MAGIC, 4, unsigned)
#define AUDIO_GET_STATS    _IOR(AUDIO_IOCTL_MAGIC, 5, unsigned)
#define AUDIO_ENABLE_AUDPP _IOW(AUDIO_IOCTL_MAGIC, 6, unsigned)
#define AUDIO_SET_ADRC     _IOW(AUDIO_IOCTL_MAGIC, 7, unsigned)
#define AUDIO_SET_EQ       _IOW(AUDIO_IOCTL_MAGIC, 8, unsigned)
#define AUDIO_SET_RX_IIR   _IOW(AUDIO_IOCTL_MAGIC, 9, unsigned)

#define EQ_MAX_BAND_NUM	12

#define ADRC_ENABLE  0x0001
#define ADRC_DISABLE 0x0000
#define EQ_ENABLE    0x0002
#define EQ_DISABLE   0x0000
#define IIR_ENABLE   0x0004
#define IIR_DISABLE  0x0000

struct eq_filter_type
{
  int16_t gain;
  uint16_t freq;
  uint16_t type;
  uint16_t qf;
};

struct eqalizer
{
  uint16_t bands;
  uint16_t params[132];
};

struct rx_iir_filter
{
  uint16_t num_bands;
  uint16_t iir_params[48];
};


struct msm_audio_config
{
  uint32_t buffer_size;
  uint32_t buffer_count;
  uint32_t channel_count;
  uint32_t sample_rate;
  uint32_t codec_type;
  uint32_t unused[3];
};

struct msm_audio_stats
{
  uint32_t out_bytes;
  uint32_t unused[3];
};

/* Audio routing */

#define SND_IOCTL_MAGIC 's'

#define SND_MUTE_UNMUTED 0
#define SND_MUTE_MUTED   1

struct msm_snd_device_config
{
  uint32_t device;
  uint32_t ear_mute;
  uint32_t mic_mute;
};

#define SND_SET_DEVICE _IOW(SND_IOCTL_MAGIC, 2, struct msm_device_config *)

#define SND_METHOD_VOICE 0

#define SND_METHOD_VOICE_1 1

struct msm_snd_volume_config
{
  uint32_t device;
  uint32_t method;
  uint32_t volume;
};

#define SND_SET_VOLUME _IOW(SND_IOCTL_MAGIC, 3, struct msm_snd_volume_config *)

/* Returns the number of SND endpoints supported. */

#define SND_GET_NUM_ENDPOINTS _IOR(SND_IOCTL_MAGIC, 4, unsigned *)

struct msm_snd_endpoint
{
  int id;			/* input and output */
  char name[64];		/* output only */
};

/* Takes an index between 0 and one less than the number returned by
 * SND_GET_NUM_ENDPOINTS, and returns the SND index and name of a
 * SND endpoint.  On input, the .id field contains the number of the
 * endpoint, and on exit it contains the SND index, while .name contains
 * the description of the endpoint.
 */

#define SND_GET_ENDPOINT _IOWR(SND_IOCTL_MAGIC, 5, struct msm_snd_endpoint *)

#endif
/* ----------  -------- */

int
msm72xx_enable_audpp (uint16_t enable_mask)
{
  int fd;

//  if (!audpp_filter_inited)
//    return -1;

  fd = open ("/dev/msm_pcm_ctl", O_RDWR);
  if (fd < 0)
    {
      perror ("Cannot open audio device");
      return -1;
    }

  if (enable_mask & ADRC_ENABLE)
    enable_mask &= ~ADRC_ENABLE;
  if (enable_mask & EQ_ENABLE)
    enable_mask &= ~EQ_ENABLE;
  if (enable_mask & IIR_ENABLE)
    enable_mask &= ~IIR_ENABLE;

  printf ("msm72xx_enable_audpp: 0x%04x", enable_mask);
  if (ioctl (fd, AUDIO_ENABLE_AUDPP, &enable_mask) < 0)
    {
      perror ("enable audpp error");
      close (fd);
      return -1;
    }

  close (fd);
  return 0;
}

int
do_route_audio_rpc (uint32_t device, int ear_mute, int mic_mute)
{
  if (device == -1UL)
    return 0;

  int fd;

  printf ("rpc_snd_set_device(%d, %d, %d)\n", device, ear_mute, mic_mute);

  fd = open ("/dev/msm_snd", O_RDWR);
  if (fd < 0)
    {
      perror ("Can not open snd device");
      return -1;
    }
  // RPC call to switch audio path
  /* rpc_snd_set_device(
   *     device,            # Hardware device enum to use
   *     ear_mute,          # Set mute for outgoing voice audio
   *                        # this should only be unmuted when in-call
   *     mic_mute,          # Set mute for incoming voice audio
   *                        # this should only be unmuted when in-call or
   *                        # recording.
   *  )
   */
  struct msm_snd_device_config args;
  args.device = device;
  args.ear_mute = ear_mute ? SND_MUTE_MUTED : SND_MUTE_UNMUTED;
  args.mic_mute = mic_mute ? SND_MUTE_MUTED : SND_MUTE_UNMUTED;

  if (ioctl (fd, SND_SET_DEVICE, &args) < 0)
    {
      perror ("snd_set_device error.");
      close (fd);
      return -1;
    }

  close (fd);
  return 0;
}

int
set_volume_rpc (uint32_t device, uint32_t method, uint32_t volume)
{
  int fd;

  printf ("rpc_snd_set_volume(%d, %d, %d)\n", device, method, volume);

  if (device == -1UL)
    return 0;

  fd = open ("/dev/msm_snd", O_RDWR);
  if (fd < 0)
    {
      perror ("Can not open snd device");
      return -1;
    }
  /* rpc_snd_set_volume(
   *     device,            # Any hardware device enum, including
   *                        # SND_DEVICE_CURRENT
   *     method,            # must be SND_METHOD_VOICE to do anything useful
   *     volume,            # integer volume level, in range [0,5].
   *                        # note that 0 is audible (not quite muted)
   *  )
   * rpc_snd_set_volume only works for in-call sound volume.
   */
  struct msm_snd_volume_config args;
  args.device = device;
  args.method = method;
  args.volume = volume;

  if (ioctl (fd, SND_SET_VOLUME, &args) < 0)
    {
      perror ("snd_set_volume error.");
      close (fd);
      return -1;
    }
  close (fd);
  return 0;
}


int
pcm_play (unsigned rate, unsigned channels,
	  int (*fill) (void *buf, unsigned sz, void *cookie), void *cookie)
{
  struct msm_audio_config config;
  struct msm_audio_stats stats;
  unsigned sz, n;
  char buf[8192];
  int afd;

  afd = open ("/dev/msm_pcm_out", O_RDWR);
  if (afd < 0)
    {
      perror ("pcm_play: cannot open audio device");
      return -1;
    }

  if (ioctl (afd, AUDIO_GET_CONFIG, &config))
    {
      perror ("could not get config");
      return -1;
    }

  config.channel_count = channels;
  config.sample_rate = rate;
  if (ioctl (afd, AUDIO_SET_CONFIG, &config))
    {
      perror ("could not set config");
      return -1;
    }
  sz = config.buffer_size;
  if (sz > sizeof (buf))
    {
      fprintf (stderr, "too big\n");
      return -1;
    }

  fprintf (stderr, "prefill\n");
  for (n = 0; n < config.buffer_count; n++)
    {
      if (fill (buf, sz, cookie))
	break;
      if (write (afd, buf, sz) != sz)
	break;
    }

  fprintf (stderr, "start\n");
  ioctl (afd, AUDIO_START, 0);

  for (;;)
    {
#if 0
      if (ioctl (afd, AUDIO_GET_STATS, &stats) == 0)
	fprintf (stderr, "%10d\n", stats.out_bytes);
#endif
      if (fill (buf, sz, cookie))
	break;
      if (write (afd, buf, sz) != sz)
	break;
    }

done:
  close (afd);
  return 0;
}

/* http://ccrma.stanford.edu/courses/422/projects/WaveFormat/ */

#define ID_RIFF 0x46464952
#define ID_WAVE 0x45564157
#define ID_FMT  0x20746d66
#define ID_DATA 0x61746164

#define FORMAT_PCM 1

struct wav_header
{
  uint32_t riff_id;
  uint32_t riff_sz;
  uint32_t riff_fmt;
  uint32_t fmt_id;
  uint32_t fmt_sz;
  uint16_t audio_format;
  uint16_t num_channels;
  uint32_t sample_rate;
  uint32_t byte_rate;		/* sample_rate * num_channels * bps / 8 */
  uint16_t block_align;		/* num_channels * bps / 8 */
  uint16_t bits_per_sample;
  uint32_t data_id;
  uint32_t data_sz;
};


static char *next;
static unsigned avail;

int
fill_buffer (void *buf, unsigned sz, void *cookie)
{
  if (sz > avail)
    return -1;
  memcpy (buf, next, sz);
  next += sz;
  avail -= sz;
  return 0;
}

void
play_file (unsigned rate, unsigned channels, int fd, unsigned count)
{
  next = malloc (count);
  if (!next)
    {
      fprintf (stderr, "could not allocate %d bytes\n", count);
      return;
    }
  if (read (fd, next, count) != count)
    {
      fprintf (stderr, "could not read %d bytes\n", count);
      return;
    }
  avail = count;
  pcm_play (rate, channels, fill_buffer, 0);
}

int
wav_play (const char *fn)
{
  struct wav_header hdr;
  unsigned rate, channels;
  int fd;
  fd = open (fn, O_RDONLY);
  if (fd < 0)
    {
      fprintf (stderr, "playwav: cannot open '%s'\n", fn);
      return -1;
    }
  if (read (fd, &hdr, sizeof (hdr)) != sizeof (hdr))
    {
      fprintf (stderr, "playwav: cannot read header\n");
      return -1;
    }
  fprintf (stderr, "playwav: %d ch, %d hz, %d bit, %s\n",
	   hdr.num_channels, hdr.sample_rate, hdr.bits_per_sample,
	   hdr.audio_format == FORMAT_PCM ? "PCM" : "unknown");

  if ((hdr.riff_id != ID_RIFF) ||
      (hdr.riff_fmt != ID_WAVE) || (hdr.fmt_id != ID_FMT))
    {
      fprintf (stderr, "playwav: '%s' is not a riff/wave file\n", fn);
      return -1;
    }
  if ((hdr.audio_format != FORMAT_PCM) || (hdr.fmt_sz != 16))
    {
      fprintf (stderr, "playwav: '%s' is not pcm format\n", fn);
      return -1;
    }
  if (hdr.bits_per_sample != 16)
    {
      fprintf (stderr, "playwav: '%s' is not 16bit per sample\n", fn);
      return -1;
    }

  play_file (hdr.sample_rate, hdr.num_channels, fd, hdr.data_sz);

  return 0;
}

int
wav_rec (const char *fn, unsigned channels, unsigned rate)
{
  struct wav_header hdr;
  unsigned char buf[8192];
  struct msm_audio_config cfg;
  unsigned sz, n;
  int fd, afd;
  unsigned total = 0;
  unsigned char tmp;

  hdr.riff_id = ID_RIFF;
  hdr.riff_sz = 0;
  hdr.riff_fmt = ID_WAVE;
  hdr.fmt_id = ID_FMT;
  hdr.fmt_sz = 16;
  hdr.audio_format = FORMAT_PCM;
  hdr.num_channels = channels;
  hdr.sample_rate = rate;
  hdr.byte_rate = hdr.sample_rate * hdr.num_channels * 2;
  hdr.block_align = hdr.num_channels * 2;
  hdr.bits_per_sample = 16;
  hdr.data_id = ID_DATA;
  hdr.data_sz = 0;

  fd = open (fn, O_CREAT | O_RDWR, 0666);
  if (fd < 0)
    {
      perror ("cannot open output file");
      return -1;
    }
  write (fd, &hdr, sizeof (hdr));

  afd = open ("/dev/msm_pcm_in", O_RDWR);
  if (afd < 0)
    {
      perror ("cannot open msm_pcm_in");
      close (fd);
      return -1;
    }

  /* config change should be a read-modify-write operation */
  if (ioctl (afd, AUDIO_GET_CONFIG, &cfg))
    {
      perror ("cannot read audio config");
      goto fail;
    }

  cfg.channel_count = hdr.num_channels;
  cfg.sample_rate = hdr.sample_rate;
  if (ioctl (afd, AUDIO_SET_CONFIG, &cfg))
    {
      perror ("cannot write audio config");
      goto fail;
    }

  if (ioctl (afd, AUDIO_GET_CONFIG, &cfg))
    {
      perror ("cannot read audio config");
      goto fail;
    }

  sz = cfg.buffer_size;
  fprintf (stderr, "buffer size %d x %d\n", sz, cfg.buffer_count);
  if (sz > sizeof (buf))
    {
      fprintf (stderr, "buffer size %d too large\n", sz);
      goto fail;
    }

  if (ioctl (afd, AUDIO_START, 0))
    {
      perror ("cannot start audio");
      goto fail;
    }

  fcntl (0, F_SETFL, O_NONBLOCK);
  fprintf (stderr, "\n*** RECORDING * HIT ENTER TO STOP ***\n");

  for (;;)
    {
      while (read (0, &tmp, 1) == 1)
	{
	  if ((tmp == 13) || (tmp == 10))
	    goto done;
	}
      if (read (afd, buf, sz) != sz)
	{
	  perror ("cannot read buffer");
	  goto fail;
	}
      if (write (fd, buf, sz) != sz)
	{
	  perror ("cannot write buffer");
	  goto fail;
	}
      total += sz;

    }
done:
  close (afd);

  /* update lengths in header */
  hdr.data_sz = total;
  hdr.riff_sz = total + 8 + 16 + 8;
  lseek (fd, 0, SEEK_SET);
  write (fd, &hdr, sizeof (hdr));
  close (fd);
  return 0;

fail:
  close (afd);
  close (fd);
  unlink (fn);
  return -1;
}

int
mp3_play (const char *fn)
{
  char buf[64 * 1024];
  int r;
  int fd, afd;

  fd = open (fn, O_RDONLY);
  if (fd < 0)
    {
      perror ("cannot open mp3 file");
      return -1;
    }

  afd = open ("/dev/msm_mp3", O_RDWR);
  if (afd < 0)
    {
      close (fd);
      perror ("cannot open mp3 output device");
      return -1;
    }

  fprintf (stderr, "MP3 PLAY\n");
  ioctl (afd, AUDIO_START, 0);

  for (;;)
    {
      r = read (fd, buf, 64 * 1024);
      if (r <= 0)
	break;
      r = write (afd, buf, r);
      if (r < 0)
	break;
    }

  close (fd);
  close (afd);

  return 0;
}

#if 0

int
main (int argc, char **argv)
{
  const char *fn = 0;
  int play = 1;
  unsigned channels = 1;
  unsigned rate = 44100;

  argc--;
  argv++;
  while (argc > 0)
    {
      if (!strcmp (argv[0], "-rec"))
	{
	  play = 0;
	}
      else if (!strcmp (argv[0], "-play"))
	{
	  play = 1;
	}
      else if (!strcmp (argv[0], "-stereo"))
	{
	  channels = 2;
	}
      else if (!strcmp (argv[0], "-mono"))
	{
	  channels = 1;
	}
      else if (!strcmp (argv[0], "-rate"))
	{
	  argc--;
	  argv++;
	  if (argc == 0)
	    {
	      fprintf (stderr, "playwav: -rate requires a parameter\n");
	      return -1;
	    }
	  rate = atoi (argv[0]);
	}
      else
	{
	  fn = argv[0];
	}
      argc--;
      argv++;
    }

  if (fn == 0)
    {
      fn = play ? "/data/out.wav" : "/data/rec.wav";
    }


  int fd = open ("/dev/msm_snd", O_RDWR);
  int mNumSndEndpoints;

  if (fd >= 0)
    {
      int rc = ioctl (fd, SND_GET_NUM_ENDPOINTS,
		      &mNumSndEndpoints);

      printf ("found %d snd endpoints\n", mNumSndEndpoints);

      if (rc >= 0)
	{
	  struct msm_snd_endpoint ept;
	  int cnt;

	  for (cnt = 0; cnt < mNumSndEndpoints; cnt++)
	    {
	      ept.id = cnt;
	      ioctl (fd, SND_GET_ENDPOINT, &ept);
	      printf ("    %02d: %s / %d\n", cnt, ept.name, ept.id);
	    }
	}
      else
	perror ("Could not retrieve number of MSM SND endpoints.");
      close (fd);
    }
  else
    perror ("Could not open MSM SND driver.");

  printf ("Select device %d.\n", 1);

  do_route_audio_rpc (1, SND_MUTE_MUTED, SND_MUTE_MUTED);
//  do_route_audio_rpc(0,SND_MUTE_UNMUTED,SND_MUTE_UNMUTED);


//  printf ("enable PP\n");
//  msm72xx_enable_audpp(ADRC_ENABLE | EQ_ENABLE | IIR_ENABLE);

  printf ("Set master volume to %d.\n", 5);
#if 0
  set_volume_rpc (SND_DEVICE_HANDSET, SND_METHOD_VOICE, vol);
  set_volume_rpc (SND_DEVICE_SPEAKER, SND_METHOD_VOICE, vol);
  set_volume_rpc (SND_DEVICE_BT, SND_METHOD_VOICE, vol);
  set_volume_rpc (SND_DEVICE_HEADSET, SND_METHOD_VOICE, vol);
#endif

  /* dev=0xd ? */
  set_volume_rpc (0xd, SND_METHOD_VOICE_1, 5);

  if (play)
    {
      const char *dot = strrchr (fn, '.');
      if (dot && !strcmp (dot, ".mp3"))
	{
	  return mp3_play (fn);
	}
      else
	{
	  return wav_play (fn);
	}
    }
  else
    {
      return wav_rec (fn, channels, rate);
    }
  return 0;
}

#endif
