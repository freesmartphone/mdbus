
static void forward_data(int source_fd, int dest_fd)
{
    fd_set rfds;
    int retval;

    unsigned char buf[4096];

    int max_fd = source_fd > dest_fd ? source_fd + 1 : dest_fd + 1;

    for (;;) {
        FD_ZERO(&rfds);
        FD_SET(source_fd, &rfds);
        FD_SET(dest_fd, &rfds);

        retval = select(max_fd, &rfds, NULL, NULL, NULL);
        if (retval == -1) {
            perror("select()");
            break;
        } else if (retval){
            if (FD_ISSET(source_fd, &rfds)) {
                ssize_t size = read(source_fd, &buf, sizeof(buf));
                if (size <= 0)
                    break;

                printf("Sending from source %d\n", size);
                write(dest_fd, &buf, size);
            } else if (FD_ISSET(dest_fd, &rfds)) {
                ssize_t size = read(dest_fd, &buf, sizeof(buf));
                if (size <= 0)
                    break;

                printf("Sending from destination %d\n", size);
                write(source_fd, &buf, size);
            }
        }
    }
}
