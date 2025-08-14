MODULE_PATH="/data/adb/modules/EnCorinVest"
source "$MODULE_PATH/Scripts/encorinFunctions.sh"
source "$MODULE_PATH/Scripts/encoreTweaks.sh"
source "$MODULE_PATH/Scripts/mtkvest.sh"
source "$MODULE_PATH/Scripts/corin.sh"

mediatek() {
    corin_powersave_common
	corin_powersave_extra
    sleep 120
	encore_balanced_common
	encore_mediatek_normal
	mtkvest_normal
	corin_balanced
}

snapdragon() {
    corin_powersave_common
	corin_powersave_extra
    sleep 120
	encore_balanced_common
	encore_snapdragon_normal
	corin_balanced
}

unisoc() {
    corin_powersave_common
	corin_powersave_extra
    sleep 120
	encore_balanced_common
	encore_unisoc_normal
	corin_balanced
}

exynos() {
    corin_powersave_common
	corin_powersave_extra
    sleep 120
	encore_balanced_common
	encore_exynos_normal
	corin_balanced
}

ambatusoc
notification "EnCorinVest - Cooling Done"
dnd_off
bypass_off