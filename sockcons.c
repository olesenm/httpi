#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

/* sockcons (C)1999, 2000 Cameron Kaiser -- for HTTPi 1.3
 *
 * A hack to dump major socket constants (somewhat more trustworthy than
 * Socket.pm on some [misconfigured?] systems). Known to compile with cc
 * and gcc on HP/UX, and gcc on SunOS, Linux, AIX and NetBSD.
 */

int main(argv, argc) {
	printf("cons %i %i %i %i %i %i %i\n", AF_INET, PF_INET, SOCK_STREAM,
		SOL_SOCKET, SO_REUSEADDR, SOMAXCONN, IPPROTO_TCP);
	exit(0);
}

