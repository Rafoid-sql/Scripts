multipath -l
multipath -f <device> (mpathx)

echo 1 > /sys/block/<device-name>/device/delete (sdx)
echo 1 > /sys/block/sdg/device/delete