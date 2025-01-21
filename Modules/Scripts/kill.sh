for pkg in $(pm list packages -3 | cut -f 2 -d ":"); do
    if [[ $pkg != *"com.android"* && $pkg != *"android"* ]]; then
        am force-stop $pkg
    fi
done

echo 3 > /proc/sys/vm/drop_caches
am kill-all

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' -i file:///data/local/tmp/logo.png -I file:///data/local/tmp/logo.png TagEncorin 'EnCorinVest Killed All Apps - カリン・ウィクス & 安可'"

