/*
 * Forward a serial over TCP/IP
 *
 * Copyright (C) 2008 Openmoko Inc.
 *
 * Author: Holger Hans Peter Freyther <zecke@openmoko.org>
 * Minor enhancements by Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/ioctl.h>

#include <netinet/in.h>

#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <strings.h>

#include "forward.h"

int lflag = ICANON;

/*
 * Read from modem_fd   => write to remote_fd
 * Read from remote_fd  => write to modem_fd
 */

static void set_termios(int modem_fd)
{
    struct termios t;
    bzero(&t, sizeof(t));

    t.c_cflag = CRTSCTS | CS8 | CLOCAL | CREAD;
    t.c_iflag = IGNPAR;
    speed_t speed = B115200;
    cfsetispeed(&t, speed);
    cfsetospeed(&t, speed);

    t.c_oflag = 0;
    t.c_lflag = lflag;
    t.c_cc[VINTR]    = 0;     /* Ctrl-c */
    t.c_cc[VQUIT]    = 0;     /* Ctrl-\ */
    t.c_cc[VERASE]   = 0;     /* del */
    t.c_cc[VKILL]    = 0;     /* @ */
    t.c_cc[VEOF]     = 4;     /* Ctrl-d */
    t.c_cc[VTIME]    = 0;     /* inter-character timer unused */
    t.c_cc[VMIN]     = 1;     /* blocking read until 1 character arrives */
    t.c_cc[VSWTC]    = 0;     /* '\0' */
    t.c_cc[VSTART]   = 0;     /* Ctrl-q */
    t.c_cc[VSTOP]    = 0;     /* Ctrl-s */
    t.c_cc[VSUSP]    = 0;     /* Ctrl-z */
    t.c_cc[VEOL]     = 0;     /* '\0' */
    t.c_cc[VREPRINT] = 0;     /* Ctrl-r */
    t.c_cc[VDISCARD] = 0;     /* Ctrl-u */
    t.c_cc[VWERASE]  = 0;     /* Ctrl-w */
    t.c_cc[VLNEXT]   = 0;     /* Ctrl-v */
    t.c_cc[VEOL2]    = 0;     /* '\0' */

    tcflush(modem_fd, TCIFLUSH);
    if(tcsetattr(modem_fd, TCSANOW, &t) < 0)
        perror("tcsetattr()");

    int status = TIOCM_DTR | TIOCM_RTS;
    ioctl(modem_fd, TIOCMBIS, &status);
}

int main(int argc, char** argv)
{
    if (argc < 3)
    {
    	printf("Usage: ./forward <devicenode> <port> [raw]\n");
    	return EXIT_FAILURE;
    }
    if (argc >= 4)
    {
    	lflag = 0;
    }

    int modem_fd = open(argv[1], O_RDWR | O_NOCTTY);
    if (modem_fd < 0) {
        perror("Failed to open device");
        return EXIT_FAILURE;
    }


    set_termios(modem_fd);

    int socket_fd = socket(PF_INET, SOCK_STREAM, 0);
    if (socket_fd < 0) {
        perror("Failed to create network socket");
        return EXIT_FAILURE;
    }


    struct sockaddr_in addr = { 0, };
    addr.sin_family = PF_INET;
    addr.sin_port = htons( atoi(argv[2]) );
    addr.sin_addr.s_addr = htonl(INADDR_ANY);

    if (bind(socket_fd, (struct sockaddr*)&addr, sizeof(addr)) == -1) {
        perror("Error binding");
        return EXIT_FAILURE;
    }


    if (listen(socket_fd, 1) == -1) {
        perror("Error listening");
        return EXIT_FAILURE;
    }

    int connection_fd = -1;
    socklen_t length = sizeof(addr);
    while ((connection_fd = accept(socket_fd, (struct sockaddr*)&addr, &length)) >= 0) {
        printf("New connection from: '%s'\n", inet_ntoa(addr.sin_addr));

        forward_data(modem_fd, connection_fd);
        close(connection_fd);
    }
}
