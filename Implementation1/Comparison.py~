import os
from binascii import hexlify

if __name__ == "__main__":
    dir_list = os.listdir(os.path.dirname(os.path.realpath(__file__)))
    count = 0
    sig = '803dc6730726c605cf4febf026ff0603'
    for filename in dir_list:
        with open(filename, "r") as f:
            content = f.read()
            newcontent = hexlify(content)

        if sig in newcontent:
            count = count + 1

    rate = float(count) / len(dir_list)
    print "[%s" % sig,
    print ",",
    print " %f]" % rate
    print len(dir_list)
