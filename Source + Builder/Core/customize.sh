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
ui_print "      SNAPDRAGON | MEDIATEK         "
ui_print "          EXYNOS | UniSoc           "
ui_print "------------------------------------"
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
ui_print "Version : 21.1"
ui_print "Variant: Core"
ui_print "Support Root : Magisk / KernelSU / APatch"
ui_print " "
sleep 1.5

ui_print "       INSTALLING EnCorinVest       "
ui_print " "
sleep 1.5

unzip -o "$ZIPFILE" 'Scripts/*' -d $MODPATH >&2
cp -r "$MODPATH"/logo.png /data/local/tmp >/dev/null 2>&1
cp -r "$MODPATH"/Anya.png /data/local/tmp >/dev/null 2>&1

set_perm_recursive $MODPATH 0 0 0755 0755
set_perm_recursive $MODPATH/Scripts 0 0 0777 0755

sleep 1.5

ui_print "     INSTALLING EnCorinVest APK       "
ui_print " "

cp "$MODPATH"/EnCorinVest.apk /data/local/tmp >/dev/null 2>&1
pm install /data/local/tmp/EnCorinVest.apk >/dev/null 2>&1
rm /data/local/tmp/EnCorinVest.apk >/dev/null 2>&1

case "$((RANDOM % 14 + 1))" in
1) ui_print "- Wooly's Fairy Tale [Rem01 Gaming]" ;;
2) ui_print "- Sheep-counting Lullaby [Rem01 Gaming]" ;;
3) ui_print "- Fog? The Black Shores! [Rem01 Gaming]" ;;
4) ui_print "- Adventure? Let's go! [Rem01 Gaming]" ;;
5) ui_print "- Hero Takes the Stage! [Rem01 Gaming]" ;;
6) ui_print "- Woolies Save the World! [Rem01 Gaming]" ;;
7) ui_print "- I Cast Testicular Torsion!!! [Nazephyrus]" ;;
8) ui_print "- We Are KLC! [Kanagawa Yamada]" ;;
9) ui_print "- Gacor Kang [Nazephyrus]" ;;
10) ui_print "- Don't look back with regret, look forward with hope [Kentarou]" ;;
11) ui_print "- Go Beyond - Plus Ultra! [Momin]" ;;
12) ui_print "- Cheeki Breeki IV Damke [Ody]" ;;
13) ui_print "- Hope You Hydrated Well ❤️ [Ody]" ;;
14) ui_print "- The List Is Not Even 20 Yet [Kanagawa Yamada]" ;;
esac
