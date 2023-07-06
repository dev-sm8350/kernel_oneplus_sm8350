#!/usr/bin/env bash
#
# Copyright (C) 2022 Divyanshu-Modi <divyan.m05@gmail.com>
#
# based on <pig.priv@gmail.com> module importer
#
# SPDX-License-Identifier: Apache-2.0
#

R='\033[1;31m'
G='\033[1;32m'
W='\033[1;37m'

echo -e "$G                 ___   __                 _  __     "
echo -e "$G                /   | / /_____  ________ | |/ /     "
echo -e "$G               / /| |/ __/ __ \/ __  __ \|   /      "
echo -e "$G              / ___ / /_/ /_/ / / / / / /   |       "
echo -e "$G             /_/  |_\__/\____/_/ /_/ /_/_/|_|       "
echo -e "$G           __  ___ ___  ____  __  __ _    ______    "
echo -e "$G          /  |/  / __ \/ __ \/ / / / /   / ____/    "
echo -e "$G         / /|_/ / / / / / / / / / / /   / __/       "
echo -e "$G        / /  / / /_/ / /_/ / /_/ / /___/ /___       "
echo -e "$G       /_/  /_/\____/_____/\____/_____/_____/       "
echo -e "$G     ______  _______  ____  ____  ________________  "
echo -e "$G    /  _/  |/  / __ \/ __ \/ __ \/_  __/ ____/ __ \ "
echo -e "$G    / // /|_/ / /_/ / / / / /_/ / / / / __/ / /_/ / "
echo -e "$G  _/ // /  / / ____/ /_/ / _, _/ / / / /___/ _, _/  "
echo -e "$G /___/_/  /_/_/    \____/_/ |_| /_/ /_____/_/ |_|   "
echo -e "$W"

error() {
	clear
	echo -e ""
	echo -e "$R Error! $W" "$@"
	echo -e ""
	exit 1
}

success() {
	echo -e ""
	echo -e "$G" "$@" "$W"
	echo -e ""
}

# Commonised Importer
importer() {
	MTD=$1
	DIR=$2
	REPO=$3
	TAG=$4
	if [[ -d $DIR && $MTD == "SUBTREE" ]]; then
		error "$DIR directory is already present."
	fi
	if [[ $MTD == MERGE || $MTD == UPDATE ]]; then
		git fetch "$REPO" "$TAG"
	fi
	case "$MTD" in
		SUBTREE)
			MSG=$5
			git subtree add --prefix="$DIR" "$REPO" "$TAG" -m "$MSG"
			git commit --amend --no-edit
			;;
		MERGE)
			git merge --allow-unrelated-histories -s ours --no-commit FETCH_HEAD
			git read-tree --prefix="$DIR" -u FETCH_HEAD
			git commit --no-edit
			;;
		UPDATE)
			git merge -X subtree="$DIR" FETCH_HEAD --no-edit
			;;
	esac
}

# Import dts
dts_import() {
	if [ "$kv" = '4.19' ]; then
		msg="ARM64: dts/vendor: Import DTS for SDM660 family"
		importer "SUBTREE" "arch/arm64/boot/dts/vendor" https://github.com/Atom-X-Devs/android_kernel_qcom_devicetree "$msg"
	elif [ "$kv" = '5.4' ]; then
		msg="Arm64: dts/vendor: Import DTS for lahaina family"
		importer "SUBTREE" "arch/arm64/boot/dts/vendor" https://github.com/Divyanshu-Modi/kernel-devicetree AtomX "$msg"
		for i in camera display; do
			msg="Arm64: dts: vendor/qcom: Import $i DTS for lahaina family"
			importer "SUBTREE" "arch/arm64/boot/dts/vendor/qcom/$i" https://github.com/Divyanshu-Modi/kernel-${i}-devicetree main "$msg"
		done
	else
		error 'Invalid target kernel version, supported kernel versions are 4.19 and 5.4'
	fi

	success "Successfully imported DTS on $kv"
}

# Import exFAT
exfat_import() {
	if [ "$option" = 'u' ]; then
		msg="fs/exfat: Update from arter97/exfat-linux"
		importer "UPDATE" "fs/exfat" https://github.com/arter97/exfat-linux master "$msg"
		success "Successfully updated exFAT"
	else
		msg="fs: Import exFAT driver"
		importer "SUBTREE" "fs/exfat" https://github.com/arter97/exfat-linux master "$msg"
		success "Successfully imported exFAT"
	fi
}

# Import mainline exFAT
mainline_exfat_import() {
	if [ "$option" = 'u' ]; then
		msg="fs/exfat: Update from namjaejeon/linux-exfat-oot"
		importer "UPDATE" "fs/exfat" https://github.com/namjaejeon/linux-exfat-oot master "$msg"
		success "Successfully updated mainline exFAT"
	else
		msg="fs: Import mainline exFAT driver"
		importer "SUBTREE" "fs/exfat" https://github.com/namjaejeon/linux-exfat-oot master "$msg"
		success "Successfully imported mainline exFAT"
	fi
}

# Import tfa98xx codecs
tfa98_import() {
	read -rp "Enter branch name: " branchname
	if [ "$option" = 'u' ]; then
		msg="techpack/audio: codecs: Updated tfa98xx codec from CLO"
		importer "UPDATE" "techpack/audio/asoc/codecs/tfa9874" http://git.codelinaro.org/external/mas/tfa98xx "$branchname" "$msg"
		success "Successfully updated tfa98xx codec"
	else
		msg="techpack/audio: codecs: Initial tfa98xx codec import from CLO"
		importer "MERGE" "techpack/audio/asoc/codecs/tfa9874" http://git.codelinaro.org/external/mas/tfa98xx "$branchname" "$msg"
		success "Successfully imported tfa98xx codec"
	fi
}

# Import Kprofiles
kprofiles_import() {
	if [ "$option" = 'u' ]; then
		msg="kprofiles: Update from dakkshesh07/Kprofiles"
		importer "UPDATE" "drivers/misc/kprofiles" https://github.com/dakkshesh07/Kprofiles main "$msg"
		success "Successfully updated Kprofiles"
	else
		msg="drivers/misc: Introduce KernelSpace Profile Modes"
		importer "SUBTREE" "drivers/misc/kprofiles" https://github.com/dakkshesh07/Kprofiles main "$msg"
		success "Successfully imported Kprofiles"
	fi
}

# Read git cmd
readcmd() {
	case $cmd in
		s)
			msg1=$(echo '`DUMMY_TAG`' | sed s/DUMMY_TAG/"$br"/g)
			importer "SUBTREE" "$dir" clo/"$mod" "$br" "$msg from $msg1"
			;;
		m)
			if [ "$option" = 'u' ]; then
				importer "UPDATE" "$dir" clo/"$mod" "$br"
			else
				importer "MERGE" "$dir" clo/"$mod" "$br"
			fi
			;;
		*)
			error "Invalid target cmd, aborting!"
			;;
	esac
}

# Add remote
addremote() {
	if [ "$num" -lt '5' ]; then
		url=qcom-opensource/wlan/$mod
	elif [ "$num" = '7' ]; then
		url=qcom-opensource/$mod
	elif [ "$num" = '8' ] || [ "$num" = '9' ]; then
		url=qcom/opensource/$mod
	else
		url=opensource/$mod
	fi
	git remote add clo/"$mod" https://git.codelinaro.org/clo/la/platform/vendor/"$url".git

	success "Add remote for target module ${mod} done."
}

# Update/Import modules
moduler() {
	if [ "$num" -lt '5' ]; then
		msg="staging: $mod: Import"
		dir="drivers/staging/$mod"
	else
		msg="techpack: $mod: Import"
		dir="techpack/$prefix"
	fi
	if ! grep -q "$mod" .git/config; then
		addremote
	fi
	if [[ -d $dir && $option == "u" ]]; then
		cmd=m
	fi
	readcmd

	if [[ ! $(git diff HEAD~) ]]; then
		git reset -q --hard HEAD~
		success "HEAD resetted b'cuz empty commit for ${br}, ${mod}."
	else
		success "Import from target ${br} for target ${mod} done."
	fi
}

# Indicate module directories
indicatemodir() {
	if [[ $br == "" ]]; then
		error "tag not defined"
	fi

	case $num in
		1)
			mod=qcacld-3.0
			;;
		2)
			mod=qca-wifi-host-cmn
			;;
		3)
			mod=fw-api
			;;
		4)
			mod=prima
			;;
		5)
			mod=audio-kernel
			prefix=audio
			;;
		6)
			mod=camera-kernel
			prefix=camera
			;;
		7)
			mod=data-kernel
			prefix=data
			;;
		8)
			mod=datarmnet
			prefix=$mod
			;;
		9)
			mod=datarmnet-ext
			prefix=$mod
			;;
		10)
			mod=dataipa
			prefix=$mod
			;;
		11)
			mod=display-drivers
			prefix=display
			;;
		12)
			mod=video-driver
			prefix=video
			;;
		13)
			exfat_import
			;;
		14)
			mainline_exfat_import
			;;
		15)
			kprofiles_import
			;;
		16)
			dts_import
			;;
		17)
			tfa98_import
			;;
		*)
			clear
			error "Invalid target input, aborting!"
			;;
	esac

	if [ "$num" -lt '13' ]; then
		moduler
	fi
}

# Initialize
init() {
	COLUMNS=45
	PS3="Select a module: "
	options=("qcacld-3.0" "qca-wifi-host-cmn" "fw-api" "prima" "audio-kernel"
		"camera-kernel" "data-kernel" "datarmnet" "datarmnet-ext"
		"dataipa" "display-drivers" "video-driver" "exFAT driver"
		"mainline exFAT driver" "kprofiles" "device tree source" "tfa98xx")
	select modules in "${options[@]}"; do
		num=$REPLY
		case $num in
			1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17)
				if [ "$num" -le '17' ]; then
					if [[ -z $br ]]; then
						read -rp "Target tag / branch: " br
					fi
					read -rp "Import (i) / Update (u): " option
					if [[ $option != u && $num -lt '13' ]]; then
						read -rp "Target cmd: merge (m) subtree (s) " cmd
					else
						cmd=m
					fi
				elif [[ $num == "16" ]]; then
					read -rp "Target kernel version: " kv
				fi
				indicatemodir
				break
				;;
			*)
				break
				;;
		esac
	done
}

init
