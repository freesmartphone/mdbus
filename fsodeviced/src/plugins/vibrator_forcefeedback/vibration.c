/*
Copyright (C) 2013  Rico Rommel <rico@bierrommel.de>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <sys/ioctl.h>
#include <linux/input.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


void setvibration( int fd, int *id, int length, int delay, int strength , int repeat) {

    struct ff_effect effect;

    effect.type = FF_RUMBLE;
    effect.id = (__s16)*id;
    effect.u.rumble.strong_magnitude = (__u16)(0xffff / 100 * strength);
    effect.u.rumble.weak_magnitude   = 0;
    effect.replay.length = (__u16)length;
    effect.replay.delay  = (__u16)delay;
    
    ioctl(fd, EVIOCSFF, &effect);
    
    
    struct input_event play;
    play.type = EV_FF;
    play.code =  (__s16)effect.id; /* the id we got when uploading the effect */
    play.value = (__s32)repeat;
                
    write(fd, (const void*) &play, sizeof(play));
//    sleep((length + delay) / 1000);

    *id = effect.id;
}

