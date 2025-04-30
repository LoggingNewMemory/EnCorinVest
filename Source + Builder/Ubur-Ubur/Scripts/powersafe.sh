# Partial SYNC due to different purpose 
# Corin = Use old Encore + Mod script
# Encore powersave still partially synced

MODULE_PATH="/data/adb/modules/EnCorinVest"
source "$MODULE_PATH/Scripts/encorinFunctions.sh"
source "$MODULE_PATH/Scripts/encoreTweaks.sh"  
source "$MODULE_PATH/Scripts/corin.sh"
mediatek() {
	corin_powersave_common	
	encore_mediatek_powersave
	corin_powersave_extra
}

snapdragon() {
	corin_powersave_common
	encore_snapdragon_powersave
	corin_powersave_extra
}

unisoc() {
	corin_powersave_common
	encore_unisoc_powersave
	corin_powersave_extra
}
exynos() {
	corin_powersave_common
	encore_exynos_powersave
	corin_powersave_extra
}

ambatusoc
notification "EnCorinVest - Powersafe"