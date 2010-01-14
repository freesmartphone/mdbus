/*
 * Consume forwarded serial and provide a local pty
 *
 * Copyright (C) 2008 Openmoko Inc.
 *
 * Author: Holger Hans Peter Freyther <zecke@openmoko.org>
 * Minor enhancements by Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 */

#include <sys/socket.h>
#include <sys/types.h>

#include <netdb.h>
#include <netinet/in.h>

#include <pty.h>
#include <stdlib.h>
#include <limits.h>
#include <stdio.h>
#include <unistd.h>

#include "forward.h"

/*
 * Setup networking
 * Setup pty
 *
 * Forward
 */
int main(int argc, char** argv)
{
    if (argc < 2)
    {
    	printf("Usage: ./pty_forward <host> <port>\n");
    	return EXIT_FAILURE;
    }

    int socket_fd = socket(PF_INET, SOCK_STREAM, 0);
    if (socket_fd < 0) {
        perror("Failed to create network socket");
        return EXIT_FAILURE;
    }

    struct hostent* host = gethostbyname(argv[1]);
    if (!host) {
        printf("Failed to get the hostent\n");
        return EXIT_FAILURE;
    }

    struct sockaddr_in addr = { 0, };
    addr.sin_family = PF_INET;
    addr.sin_port = htons(atoi(argv[2]));
    addr.sin_addr = *(struct in_addr*)host->h_addr;

    int result = connect(socket_fd, (struct sockaddr*)&addr, sizeof(addr));
    if (result < 0) {
        perror("Connection failed");
        return EXIT_FAILURE;
    }

    /*
     *  PTY code
     */
    int master_fd;
    int slave_fd;
    char slave_name[PATH_MAX];
    result = openpty(&master_fd, &slave_fd, slave_name, NULL, NULL);
    if (result < 0) {
        perror("openpty()");
        return EXIT_FAILURE;
    }

    printf("You can now use '%s' %d %d %d\n", slave_name, socket_fd, master_fd, slave_fd);
    forward_data(socket_fd, master_fd);

    return EXIT_SUCCESS;
}
