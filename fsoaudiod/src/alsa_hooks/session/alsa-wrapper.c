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
 *
 */

#include <alsa/asoundlib.h>
#include <alsa/conf.h>
#include <alsa/pcm.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <glib.h>

extern gint fsoaudio_request_session (const gchar* pcmname);
extern gint fsoaudio_release_session (void);

static int _hook_hw_params(snd_pcm_hook_t *hook)
{
    snd_pcm_t *pcm = snd_pcm_hook_get_pcm(hook);
    if (!pcm)
        return -1;
    return fsoaudio_request_session(snd_pcm_name(pcm));
}

static int _hook_hw_free(snd_pcm_hook_t *hook)
{
    return fsoaudio_release_session();
}

static int _hook_close(snd_pcm_hook_t *hook)
{
    return 0;
}

int fsoaudio_alsa_hook_request_session_install(snd_pcm_t *pcm, snd_config_t *conf)
{
    int err;
    snd_pcm_hook_t *h_hw_params = NULL;
    snd_pcm_hook_t *h_hw_free = NULL;
    snd_pcm_hook_t *h_close = NULL;

    err = snd_pcm_hook_add(&h_hw_params, pcm, SND_PCM_HOOK_TYPE_HW_PARAMS,
                           _hook_hw_params, NULL);
    if (err < 0)
        goto error;

    err = snd_pcm_hook_add(&h_hw_free, pcm, SND_PCM_HOOK_TYPE_HW_FREE,
                           _hook_hw_free, NULL);
    if (err < 0)
        goto error;

    err = snd_pcm_hook_add(&h_close, pcm, SND_PCM_HOOK_TYPE_CLOSE,
                           _hook_close, NULL);
    if (err < 0)
        goto error;

    g_type_init();

    return 0;

error:
    if (h_hw_params)
        snd_pcm_hook_remove(h_hw_params);

    if (h_hw_free)
        snd_pcm_hook_remove(h_hw_free);

    if (h_close)
        snd_pcm_hook_remove(h_close);

    return err;
}

SND_DLSYM_BUILD_VERSION(fsoaudio_alsa_hook_request_session_install, SND_PCM_DLSYM_VERSION);

// vim:ts=4:sw=4:expandtab
