MODULE_PATH="/data/adb/modules/EnCorinVest"
source "$MODULE_PATH/Scripts/encorinFunctions.sh"
source "$MODULE_PATH/Scripts/encoreTweaks.sh"  
source "$MODULE_PATH/Scripts/mtkvest.sh"
source "$MODULE_PATH/Scripts/corin.sh"
mediatek() {
	encore_perfcommon
	encore_perfprofile
	encore_mediatek_perf
	mtkvest_perf
	corin_perf
	kill_all
}

snapdragon() {
	encore_perfcommon
	encore_perfprofile
	encore_snapdragon_perf
	corin_perf
	kill_all
}

unisoc() {
	encore_perfcommon
	encore_perfprofile
	encore_unisoc_perf
	# corin_perf
	kill_all
}
exynos() {
	encore_perfcommon
	encore_perfprofile
	encore_exynos_perf
	corin_perf
	kill_all
}

ambatusoc
notification "EnCorinVest - Gaming Pro"
