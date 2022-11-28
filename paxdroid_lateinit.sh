#! /system/bin/sh

function mount_limited_space() {
    # mount limited space (/cache/data/public's space is limited)
    if [ ! -e /cache/data/limitedspace.img ]; then
        make_ext4fs -l 26214400 /cache/data/limitedspace.img  # 25M
    fi
    mount -t ext4 -o loop /cache/data/limitedspace.img  /cache/data/public/
    chown system:system /cache/data/public/
    chmod 777 /cache/data/public/
}

function copy_customer_fonts_if_neccessary() {
    # Two reason to copy customer's fonts:
    # a. If customer resource has been updated, copy its fonts.
    # b. If system is first run, copy its fonts.

    libs_copy_flag=/cache/customer/FONTS_COPYED
    is_system_first_run=`/system/bin/getprop persist.sys.firstrun yes`
    if [ ! -e $libs_copy_flag ] || [ "$is_system_first_run" == "yes" ]; then
        # copy customer's fonts
        cp /cache/customer/fonts/*.* /data/resource/font/
        chown system:shell /data/resource/font/*.*
        chmod 664 /data/resource/font/*.*
        echo "copyed" > $libs_copy_flag
    fi
}

function copy_customer_libs_if_neccessary() {
    # Two reason to copy customer's libs:
    # a. If customer resource has been updated, copy its libs.
    # b. If system is first run, copy its libs.

    libs_copy_flag=/cache/customer/LIBS_COPYED
    is_system_first_run=`/system/bin/getprop persist.sys.firstrun yes`
    if [ ! -e $libs_copy_flag ] || [ "$is_system_first_run" == "yes" ]; then
        # copy customer's libs
        cp /cache/customer/lib/*.so /data/resource/lib/
        chown system:shell /data/resource/lib/*.so
        chmod 664 /data/resource/lib/*.so
        echo "copyed" > $libs_copy_flag
    fi
}

function execute_customer_script_if_neccesary() {
    # Two reason to execute customer's scripts:
    # a. If customer resource has been updated, execute its scripts.
    # b. If system is first run, execute its scripts.

    lateinit_executed_flag=/cache/customer/SCRIPT_LATEINIT_EXECUTED
    is_system_first_run=`/system/bin/getprop persist.sys.firstrun yes`
    if [ ! -e $lateinit_executed_flag ] || [ "$is_system_first_run" == "yes" ]; then
        # execute /cache/customer/bin/customer_lateinit.sh if exist.
        customer_lateinit_script=/cache/customer/bin/customer_lateinit.sh
        if [ -e $customer_lateinit_script ]; then
            # make sure that we have execute permission
            chmod +x $customer_lateinit_script
            /system/bin/sh $customer_lateinit_script
            echo "executed" > $lateinit_executed_flag
        fi
    fi
}

function check_recovery_result_reason() {
    # check recovery result and reason
    if [ -e /data/paxdroid.recovery.result ]; then
        recovery_result=`cat /data/paxdroid.recovery.result`
        /system/bin/setprop pax.ctrl.recovery.result $recovery_result
        rm /data/paxdroid.recovery.result
    fi

    if [ -e /data/paxdroid.recovery.reason ]; then
        recovery_reason=`cat /data/paxdroid.recovery.reason`
        /system/bin/setprop pax.ctrl.recovery.reason $recovery_reason
        if [ "$recovery_reason" == "update_package" ]; then
            # FBAU: First Boot After Update
            /system/bin/setprop pax.ctrl.is.FBAU yes
        fi
        rm /data/paxdroid.recovery.reason
    fi
}

function do_other_things() {
    # rechange sensitive directories/files's access permission
    chmod 644 /cache/customer/cert/*

    # make symlink
    ln -s /data/resource/public /Share
    ln -s /data/resource/public/tmp /tmp
}

#mount_limited_space
copy_customer_libs_if_neccessary
copy_customer_fonts_if_neccessary
execute_customer_script_if_neccesary
check_recovery_result_reason
do_other_things

# NOTE: Don't do anything that may take a long time here.
