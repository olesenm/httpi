use Socket;

	printf("cons %i %i %i %i %i %i\n", AF_INET, PF_INET, SOCK_STREAM,
		SOL_SOCKET, SO_REUSEADDR, SOMAXCONN, IPPROTO_TCP);

