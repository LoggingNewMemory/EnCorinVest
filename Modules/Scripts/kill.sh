for pkg in $(pm list packages -3 | cut -f 2 -d ":"); do am force-stop $pkg; done

su -lp 2000 -c "cmd notification post -S bigtext -t 'EnCorinVest' TagKill 'Killed All Apps! - 神奈川・山田'"

