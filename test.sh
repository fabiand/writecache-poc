
# https://serverfault.com/questions/523509/linux-how-to-simulate-hard-disk-latency-i-want-to-increase-iowait-value-withou
# https://docs.kernel.org/admin-guide/device-mapper/delay.html
# https://www.admin-magazine.com/HPC/Articles/Linux-Writecache
# https://docs.kernel.org/admin-guide/device-mapper/writecache.html
# https://www.kernel.org/doc/Documentation/device-mapper/cache.txt
# https://serverfault.com/questions/1088512/lvmcache-dm-cache-writeback-cache-full-performance

set -ex

SIZE_M=1000

#
# Create a slow device
#
dd if=/dev/zero bs=1M count=$SIZE_M of=slow.file
losetup -f slow.file
LOOP_SLOW=$(losetup -j slow.file -O NAME -n)

DM_SLOW=dm-slow
dmsetup create $DM_SLOW --table "0 $(blockdev --getsz $LOOP_SLOW) delay $LOOP_SLOW 0 100"


#
# This could also be done with LVM2
#
dd if=/dev/zero bs=1M count=$SIZE_M of=cache.file
losetup -f cache.file
LOOP_CACHE=$(losetup -j cache.file -O NAME -n)

DM_CACHE=${DM_SLOW}-writecache
dmsetup create dm-slow-writecache --table "0 $(blockdev --getsz $LOOP_SLOW) writecache s /dev/mapper/$DM_SLOW $LOOP_CACHE 4096 0"

chmod a+rw /dev/mapper/$DM_SLOW /dev/mapper/$DM_CACHE

for DST in $DM_SLOW $DM_CACHE;
do
  echo "### $DST"
  fio --bs=4k --ioengine=libaio --iodepth=32 --size=10m --direct=1 --runtime=60 --rw=randwrite --numjobs=1 --name=test --filename=/dev/mapper/$DST
done
