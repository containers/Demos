#!/usr/bin/env python3
#

import sys

def main(argv):
    for i in range(0,10):
        print ("Hello World from Container Land! Message # [%d]" % i)

if __name__ == "__main__":
    main(sys.argv[1:])
