MODULE_PATH="/data/adb/modules/EnCorinVest"
source "$MODULE_PATH/Scripts/encorinFunctions.sh"
source "$MODULE_PATH/Scripts/encoreTweaks.sh"
source "$MODULE_PATH/Scripts/mtkvest.sh"
source "$MODULE_PATH/Scripts/corin.sh"

mediatek() {
	encore_balanced_common
	log_execution "encore_balanced_common"
	encore_mediatek_normal
	log_execution "encore_mediatek_normal"
	mtkvest_normal
	log_execution "mtkvest_normal"
	corin_balanced
	log_execution "corin_balanced"
}

snapdragon() {
	encore_balanced_common
	log_execution "encore_balanced_common"
	encore_snapdragon_normal
	log_execution "encore_snapdragon_normal"
	corin_balanced
	log_execution "corin_balanced"
}

unisoc() {
	encore_balanced_common
	log_execution "encore_balanced_common"
	encore_unisoc_normal
	log_execution "encore_unisoc_normal"
	corin_balanced
	log_execution "corin_balanced"
}

exynos() {
	encore_balanced_common
	log_execution "encore_balanced_common"
	encore_exynos_normal
	log_execution "encore_exynos_normal"
	corin_balanced
	log_execution "corin_balanced"
}

ambatusoc
notification "EnCorinVest - Balanced"
dnd_off