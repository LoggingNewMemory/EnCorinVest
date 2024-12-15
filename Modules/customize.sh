LATESTARTSERVICE=true

ui_print "🗡--------------------------------🗡"
ui_print "             EnCorinVest            " 
ui_print "🗡--------------------------------🗡"
ui_print "         By: Kanagawa Yamada        "
ui_print "------------------------------------"
ui_print "      READ THE TELEGRAM MESSAGE     "
ui_print "------------------------------------"
ui_print " "
sleep 1.5

ui_print "------------------------------------"
ui_print "     ONLY SUPPORTS MEDIATEK CPU     "
ui_print "DO NOT COMBINE WITH ANY PERF MODULE!"
ui_print "------------------------------------"
ui_print " "
sleep 1.5

ui_print "-----------------📱-----------------"
ui_print "            DEVICE INFO             "
ui_print "-----------------📱-----------------"
ui_print "DEVICE : $(getprop ro.build.product) "
ui_print "MODEL : $(getprop ro.product.model) "
ui_print "MANUFACTURE : $(getprop ro.product.system.manufacturer) "
ui_print "PROC : $(getprop ro.product.board) "
ui_print "CPU : $(getprop ro.hardware) "
ui_print "ANDROID VER : $(getprop ro.build.version.release) "
ui_print "KERNEL : $(uname -r) "
ui_print "RAM : $(free | grep Mem |  awk '{print $2}') "
ui_print " "
sleep 1.5

ui_print "-----------------🗡-----------------"
ui_print "            MODULE INFO             "
ui_print "-----------------🗡-----------------"
ui_print "Name : EnCorinVest"
ui_print "Version : V 5.0"
ui_print "Support Root : Magisk / KernelSU"
ui_print " "
sleep 1.5

ui_print "       INSTALLING EnCorinVest       "
ui_print " "
sleep 1.5

unzip -o "$ZIPFILE" 'Scripts/*' -d $MODPATH >&2

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive $MODPATH/Scripts 0 0 0777 0755

sleep 1.5

ui_print "     INSTALLING EnCorinVest APK       "

cp "$MODPATH"/EnCorinVest.apk /data/local/tmp >/dev/null 2>&1
pm install /data/local/tmp/EnCorinVest.apk >/dev/null 2>&1
rm /data/local/tmp/EnCorinVest.apk >/dev/null 2>&1

am start -a android.intent.action.VIEW -d https://t.me/KanagawaLabAnnouncement/293 >/dev/null 2>&1
