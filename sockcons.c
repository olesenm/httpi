#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

/* sockcons (C)1999, 2006 Cameron Kaiser -- for HTTPi 1.3+
 *
 * A hack to dump major socket constants (somewhat more trustworthy than
 * Socket.pm on some [misconfigured?] systems). Known to compile with cc
 * on HP/UX and SunOS, and gcc on HP/UX, SunOS, Linux, AIX, Darwin, OS X
 * and NetBSD. Likely also compatible with AIX xlc.
 *
 */

int main(argv, argc) {
	printf("cons %i %i %i %i %i %i %i\n", AF_INET, PF_INET, SOCK_STREAM,
		SOL_SOCKET, SO_REUSEADDR, SOMAXCONN, IPPROTO_TCP);
	return 0;
}

