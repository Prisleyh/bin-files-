#!/system/bin/sh

function execute_customer_script_if_neccesary() {
    # Two reason to execute customer's scripts:
    # a. If customer resource has been updated, execute its scripts.
    # b. If system is first run, execute its scripts.

    bootcompleted_executed_flag=/cache/customer/SCRIPT_BOOTCOMPLETED_EXECUTED
    is_system_first_run=`/system/bin/getprop persist.sys.firstrun yes`
    if [ ! -e $bootcompleted_executed_flag ] || [ "$is_system_first_run" == "yes" ]; then
        # execute /cache/customer/bin/customer_bootcompleted.sh if exist.
        customer_bootcompleted_script=/cache/customer/bin/customer_bootcompleted.sh
        if [ -e $customer_bootcompleted_script ]; then
            # make sure that we have execute permission
            chmod +x $customer_bootcompleted_script
            /system/bin/sh $customer_bootcompleted_script
            echo "executed" > $bootcompleted_executed_flag
        fi
    fi

}

function exit_bootcompleted_check() {

    execute_customer_script_if_neccesary


    /system/bin/setprop pax.ctrl.bootchecked true
    exit
}

# remove unsigned packages
function remove_unsigned_packages_if_necessary() {
    is_app_debug=`/system/bin/getprop sys.auth.AppDebugStatus 0`
    if [ "$is_app_debug" == "0" ]; then
        unsigned_app_dir=/data/unsigned-apps
        if [ -e $unsigned_app_dir ]; then
            systool remove unsigned-apps
        fi
    fi
}

remove_unsigned_packages_if_necessary

rm /cache/recovery/command
rm  -rf  /cache/app/com.pax.smartcardmanager
customerId=`/system/bin/getprop pax.ctrl.customerId`
echo "customerId = $customerId"
# 1. If paxdroid system is first run, then do preinstall.
if [ ! -e /data/paxdroid.notfirstrun ]; then
    echo "paxdroid is first run, do preinstall jobs..."
    /system/bin/sh /system/bin/paxdroid_preinstall.sh
    echo "notfirstrun" > /data/paxdroid.notfirstrun

    rm /data/paxdroid.customer
    echo ${customerId} > /data/paxdroid.customer

    newPaxdroidVersion=`/system/bin/getprop ro.build.display.id`
    /system/bin/setprop persist.sys.paxdroid.version ${newPaxdroidVersion}

    echo "paxdroid preinstall ok"
    echo "let's get out of here"

    # if recovery happended and the customer is not lakala, then delete the wipedata.flag
    customerLaKaLa=CID_04
    if [ -e /data/wipedata.flag ] && [ "$customerId" != "$customerLaKaLa" ]; then
	rm /data/wipedata.flag
    fi
    exit_bootcompleted_check
fi

# 2. If paxdroid system is not first run, but the customer type has been changed,
#    we need to clear all apps, then clear 'system first run' flag and reboot.

if [ ! -e /data/paxdroid.customer ]; then
    echo ${customerId} > /data/paxdroid.customer
else
    oldCustomerId=`/system/bin/cat /data/paxdroid.customer`
    echo "oldCustomerId = $oldCustomerId"
    if [ "$customerId" != "$oldCustomerId" -a "$customerId" != "CID_00" ]; then
	# save the new customer name
	rm /data/paxdroid.customer
	echo ${customerId} > /data/paxdroid.customer

	# clear the "system first fun" flag
	rm /data/paxdroid.notfirstrun

	# Okay, customer name has been changed, clear all apps and user datas.
#	lastRecoverTime=`date +%Y%m%d_%H%M%S`
#	/system/bin/setprop pax.persist.RecoveryReason customerChangedOn_${lastRecoverTime}

#	/system/bin/setprop pax.ctrl.cleardatas true
#	/system/bin/systool clear datas
	# /system/bin/sh /system/bin/paxdroid_preinstall.sh
    fi
fi

# 3. If paxdroid recovery install fail, then do preinstall again.
customerLaKaLa=CID_04
if [ -e /data/wipedata.flag ] && [ "$customerId" == "$customerLaKaLa" ]; then
    echo "paxdroid recovery install fail, then do preinstall again"
    /system/bin/sh /system/bin/paxdroid_preinstall.sh
fi

# 4. the last chance to do preinstall
# We need to do preinstall after clearing apps.
if [ -e /data/clearapps.happended ]; then
    /system/bin/sh /system/bin/paxdroid_preinstall.sh
    rm /data/clearapps.happended
fi

# 5. if system has been updated, do preinstall
newPaxdroidVersion=`/system/bin/getprop ro.build.display.id`
oldPaxdroidVersion=`/system/bin/getprop persist.sys.paxdroid.version old`
if [ "$newPaxdroidVersion" != "$oldPaxdroidVersion" ]; then
    /system/bin/setprop persist.sys.paxdroid.version ${newPaxdroidVersion}
    /system/bin/sh /system/bin/paxdroid_preinstall.sh
fi

# 6. If customer resource has been updated, install its apps
if [ ! -e /cache/customer/APP_INSTALLED ]; then
    /system/bin/systool install preinstall /cache/customer/app
    /system/bin/systool install preinstall /cache/customer/app2
    echo "app_installed" > /cache/customer/APP_INSTALLED
fi

exit_bootcompleted_check
