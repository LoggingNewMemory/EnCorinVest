MODULE_PATH="/data/adb/modules/EnCorinVest"
source "$MODULE_PATH/Scripts/encorinFunctions.sh"
source "$MODULE_PATH/Scripts/encoreTweaks.sh"
source "$MODULE_PATH/Scripts/mtkvest.sh"
source "$MODULE_PATH/Scripts/corin.sh"

mediatek() {
	encore_perfcommon
    log_execution "encore_perfcommon"
	encore_perfprofile
    log_execution "encore_perfprofile"
	encore_mediatek_perf
    log_execution "encore_mediatek_perf"
	mtkvest_perf
    log_execution "mtkvest_perf"
	corin_perf
    log_execution "corin_perf"
}

snapdragon() {
	encore_perfcommon
    log_execution "encore_perfcommon"
	encore_perfprofile
    log_execution "encore_perfprofile"
	encore_snapdragon_perf
    log_execution "encore_snapdragon_perf"
	corin_perf
    log_execution "corin_perf"
}

unisoc() {
	encore_perfcommon
    log_execution "encore_perfcommon"
	encore_perfprofile
    log_execution "encore_perfprofile"
	encore_unisoc_perf
    log_execution "encore_unisoc_perf"
 	corin_perf
    log_execution "corin_perf"
}

exynos() {
	encore_perfcommon
    log_execution "encore_perfcommon"
	encore_perfprofile
    log_execution "encore_perfprofile"
	encore_exynos_perf
    log_execution "encore_exynos_perf"
	corin_perf
    log_execution "corin_perf"
}

ambatusoc
notification "EnCorinVest - Performance"
dnd_on
bypass_on