#!/system/bin/sh

echo " insmod pax pcd driver"

FILE=pcd_pn512.ko
cd /lib/modules

if [ -f "$FILE" ];then
	insmod $FILE
	echo  "$FILE  exist!"
else
	echo "the file do not exist"
	
fi
