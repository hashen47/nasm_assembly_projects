#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>


#define PRINT_FLAG(FLAG) do { \
	printf("%s: %o\n", #FLAG, FLAG); \
} while(0)
	

int main(void)
{
	PRINT_FLAG(O_RDONLY);
	PRINT_FLAG(O_WRONLY);
	PRINT_FLAG(O_RDWR);
	// PRINT_FLAG(EACCES);
	// PRINT_FLAG(EAGAIN);
	// PRINT_FLAG(EWOULDBLOCK);
	// PRINT_FLAG(EBADF);
	// PRINT_FLAG(EDESTADDRREQ);
	// PRINT_FLAG(EDQUOT);
	// PRINT_FLAG(EFAULT);
	// PRINT_FLAG(EFBIG);
	// PRINT_FLAG(EINTR);
	// PRINT_FLAG(EINVAL);
	// PRINT_FLAG(EIO);
	// PRINT_FLAG(ENOSPC);
	// PRINT_FLAG(EPERM);
	// PRINT_FLAG(EPIPE);
	PRINT_FLAG(O_TRUNC);
	PRINT_FLAG(O_CREAT);
	printf("error: %s\n", strerror(9));

	unsigned long long n1 = 23ULL;
	printf("sizeof a pointer: %zu", sizeof &n1);

	return 0;
}
