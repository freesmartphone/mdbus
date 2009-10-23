all: forward pty_forward

clean:
	rm -f forward pty_forward

forward: forward.c
	$(CC) -o forward forward.c

pty_forward: pty_forward.c
	$(CC) -lutil -o pty_forward pty_forward.c
