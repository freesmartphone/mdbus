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
#include <getopt.h>

#include "forward.h"
#include "hsuart.h"

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

static void set_hsuart(int modem_fd)
{
    int flush = 0;
    struct hsuart_mode mode;

    /* flush everything */
    flush = HSUART_RX_QUEUE | HSUART_TX_QUEUE | HSUART_RX_FIFO | HSUART_TX_FIFO;
    ioctl(modem_fd, HSUART_IOCTL_FLUSH, flush);

    /* get current mode */
    ioctl(modem_fd, HSUART_IOCTL_GET_UARTMODE, &mode);

    /* speed and flow control */
    mode.speed = HSUART_SPEED_115K;
    mode.flags |= HSUART_MODE_PARITY_NONE;
    mode.flags |= HSUART_MODE_FLOW_CTRL_HW;
    ioctl(modem_fd, HSUART_IOCTL_SET_UARTMODE, &mode);

    /* we want flow control for the rx line */
    ioctl(modem_fd, HSUART_IOCTL_RX_FLOW, HSUART_RX_FLOW_ON);
}

int main(int argc, char** argv)
{
#if 0
    if (argc < 3)
    {
    	printf("Usage: ./forward <devicenode> <port> [raw]\n");
    	return EXIT_FAILURE;
    }
    if (argc >= 4)
    {
    	lflag = 0;
    }
#endif

    opterr = 0;
    int option_index;
    int chr;
    char serial_node[30];
    int network_port;
    int check_arg[2];
    int type = 0; /* 0 = serial, 1 = palmpre hsuart */
    memset(check_arg, 0, 2);

    struct option opts[] = {
        { "raw", no_argument, 0, 'r' },
        { "node", required_argument, 0, 'n' },
        { "port", required_argument, 0, 'p' },
        { "type", required_argument, 0, 't' },
        { "help", no_argument, 0, 'h' },
    };

    while (1) {
        option_index = 0;
        chr = getopt_long(argc, argv, "rn:p:h", opts, &option_index);

        if (chr == -1)
            break;

        switch(chr) {
        case 'r':
            lflag = 0;
            break;
        case 'n':
            check_arg[0] = 1;
            snprintf(serial_node, 30, "%s", optarg);
            break;
        case 'p':
            check_arg[1] = 1;
            network_port = atoi(optarg);
            break;
        case 't':
            if (!strncmp((char*)optarg, "hsuart", 6))
                type = 1;
        default:
            break;
        }
    }

	if (!check_arg[0] || !check_arg[1]) {
		printf("please specify both a network port and the serial node to forward!\n");
		printf("use: serial_forward -n <serial node> -p <network port> [-t, --type=(serial|hsuart)] [-r, --raw]\n");
		exit(1);
	}

    int modem_fd = open(serial_node, O_RDWR | O_NOCTTY);
    if (modem_fd < 0) {
        perror("Failed to open device");
        return EXIT_FAILURE;
    }

    if (type == 0)
        set_termios(modem_fd);
    else if (type == 1)
        set_hsuart(modem_fd);

    int socket_fd = socket(PF_INET, SOCK_STREAM, 0);
    if (socket_fd < 0) {
        perror("Failed to create network socket");
        return EXIT_FAILURE;
    }


    struct sockaddr_in addr = { 0, };
    addr.sin_family = PF_INET;
    addr.sin_port = htons(network_port);
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
