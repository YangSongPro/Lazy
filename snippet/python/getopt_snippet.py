#!/usr/bin/env python

# need python3

import getopt
import sys

def usage():
    print(
        '''
        -h --help xxxxx
        '''
        )

def parse(arglist):
    try:
        opts, args =  getopt.getopt(arglist, "hp:t:m:v", ["help", "package=", "target=", "moveto="])
    except getopt.GetoptError as err:
        print(err)
        usage()
        sys.exit(1)

    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit()
        elif opt in ("-p", "--package"):
            print("package option: %s"%arg)
        elif opt in ("-t", "--target"):
            print("target option: %s"%arg)
        elif opt in ("-m", "--moveto"):
            print("moveto option: %s"%arg)
        elif opt == "-v":
            print("verbose option")
        else:
            assert False, "Invalid option: " + opt
           

def main():
    parse(sys.argv[1:])

if __name__ == '__main__':
    main()
