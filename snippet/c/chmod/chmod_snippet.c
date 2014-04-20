#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>


int main(int argc, char* argv[]) 
{
    struct stat statbuf;
    if(stat("foo", &statbuf) < 0) {
        printf("stat error for foo\n");
        exit(1);
    }
    // turn off group execute, and turn on set_group_ID
    if(chmod("foo", (statbuf.st_mode & ~S_IXGRP) | S_ISUID) < 0) {
        printf("chmod error for foo\n");
        exit(1);
    }
    // set mode to "rw-r--r--"
    if(chmod("bar", S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH) < 0) {
        printf("chmod error for bar");
        exit(1);
    }
    exit(0);
}
