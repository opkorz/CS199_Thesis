from ExtractThread import ExtractingThread
import binascii

def dual_extend(cur_top, location):

def extend(cur_top, location):
    
def move(cur_top, location):

if __name__ == "__main__":
    filename = "ALABAMAA.EXE"
    with open(filename, 'r') as f:
        content = f.read()
        newcontent = binascii.hexlify(content)
    start = 0
    end = 32
    partitioned_sigs = []
    while(end<len(newcontent)+32):
        sig1 = newcontent[start:end:]
        start += 32
        end += 32
        partitioned_sigs.append(sig1)
    partitioned_sigs_half1 = partitioned_sigs[:int(len(partitioned_sigs)/2):]
    partitioned_sigs_half2 = partitioned_sigs[int(len(partitioned_sigs))/2::]
    ExThread1 = ExtractingThread(partitioned_sigs_half1)
    ExThread2 = ExtractingThread(partitioned_sigs_half2)

    ExThread1.start()
    ExThread2.start()

    while(True):
        if not ExThread1.isAlive():
            print ExThread1.top
            print ExThread2.top
            if ExThread2.top < ExThread1.top:
                cur_top = ExThread2.top
            else:
                cur_top = ExThread1.top
            print cur_top
            break

    location = newcontent.find(cur_top[0])
    region_top1 = move(cur_top, location)
    region_top2 = extend(cur_top, location)
    if region_top1 < region_top2:
        cur_top = region_top1
    else:
        cur_top = region_top2
