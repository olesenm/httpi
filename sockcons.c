#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>

/* (C)1999 Cameron Kaiser. A very quick hack: if you don't have Socket.pm,
   configure.demonic can get your socket constants from this program (somewhat
   less reliably/portably, but we all ought to run gcc :-). */

void main(argv, argc) {
	printf("cons %i %i %i %i %i %i %i\n", AF_INET, PF_INET, SOCK_STREAM,
		SOL_SOCKET, SO_REUSEADDR, SOMAXCONN, IPPROTO_TCP);
	exit(0);
}

