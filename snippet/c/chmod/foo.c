#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char* argv[]) 
{
    char* buf = "inser this line by each execution!\n";
    int fd;
    if ((fd = open("oneline.txt", O_APPEND|O_RDWR)) < 0) {
        perror("can't open");
        exit(1);
    }
    if(write(fd, buf, strlen(buf)) < 0 ) {
        perror(argv[0]);
        exit(1);
    }
    exit(0);
}
