#!/system/bin/sh

echo " alternately the data  of sp and ap"

FILE=paxservice
cd /system/bin
if [ -f "$FILE" ];then
	./$FILE
	echo  "sp_read_write  exist!"
else
	echo "the file do not exist"
	
fi
