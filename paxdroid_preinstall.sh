#! /system/bin/sh

####### Note: this script should be called after boot completed  #######

echo "starting paxdroid late preinstall"

customer=`/system/bin/getprop pax.ctrl.customerId`
echo "customer = $customer"

# FBAU: First Boot After Update
recovery_reason=`/system/bin/getprop pax.ctrl.is.FBAU no`

lateinit_done=`/system/bin/getprop pax.ctrl.lateinit 0`
while [ $lateinit_done != "1" ]
do
    echo "lateinit not done yet, waiting ..."
    sleep 1
    lateinit_done=`/system/bin/getprop pax.ctrl.lateinit 0`
done

# xxxxxxxx just for historical reason ^~^, I don't know why we need these.
rm -rf /cache/app/com.pax.smartcardmanager
/system/bin/setprop pax.ctrl.clearapps true
pm uninstall  com.google.zxing.client.android
/system/bin/setprop pax.ctrl.clearapps false
# xxxxxxxx

# send a broadcast to tell others that we are about to do preinstall.
/system/bin/am broadcast -a com.paxdroid.intent.PREINSTALL_STATE -e preinstall_state start
echo "starting paxdroid late preinstall"
/system/bin/setprop pax.ctrl.preinstall.start true

customer_preinstall_script=/system/bin/preinstall-${customer}.sh
common_preinstall_script=/system/bin/preinstall-common.sh

if [ -e $customer_preinstall_script ];then
    /system/bin/sh $customer_preinstall_script
else
    /system/bin/sh $common_preinstall_script
fi

# send a broadcast to tell others that we have done preinstall.
echo "paxdroid late preinstall done"
/system/bin/setprop pax.ctrl.preinstall.done true
/system/bin/am broadcast -a com.paxdroid.intent.PREINSTALL_STATE -e preinstall_state done