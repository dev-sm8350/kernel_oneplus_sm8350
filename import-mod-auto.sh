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
	MSG=$5

	if [[ -d $2 && $1 == "SUBTREE" ]]; then
		error "$2 directory is already present."
	fi

	echo "Processing: $mod"
	git fetch -q "$3" "$4"

	case "$1" in
		SUBTREE)
			echo $5
			git subtree add --prefix="$2" FETCH_HEAD -m "$MSG"
			git commit --amend --no-edit
			;;
		MERGE)
			git merge --allow-unrelated-histories -s ours --no-commit FETCH_HEAD
			git read-tree --prefix="$2" -u FETCH_HEAD
			git commit --no-edit
			;;
		UPDATE)
			git merge -X subtree="$2" FETCH_HEAD --no-edit
			;;
	esac
}

# Import dts
dts_import() {
	msg="Arm64: dts/vendor: Import DTS for lahaina family"
	importer "SUBTREE" "arch/arm64/boot/dts/vendor" https://github.com/Divyanshu-Modi/kernel-devicetree redwood-s-oss "$msg"
	for i in camera display; do
		msg="Arm64: dts: vendor/qcom: Import $i DTS for lahaina family"
		importer "SUBTREE" "arch/arm64/boot/dts/vendor/qcom/$i" https://github.com/Divyanshu-Modi/kernel-${i}-devicetree redwood-s-oss "$msg"
	done

	success "Successfully imported DTS on $kv"
	exit 0
}

# Update/Import modules
moduler() {
	msg="techpack: $mod: Import"
	dir="techpack/$prefix"
	if [ "$num" -lt '4' ]; then
		msg="staging: $mod: Import"
		dir="drivers/staging/$mod"
	fi
	if ! grep -q "$mod" .git/config; then
		case $mod in
			qcacld-3.0|qca-wifi-host-cmn|fw-api)
				url=qcom-opensource/wlan/$mod
				;;
			datarmnet-ext|datarmnet)
				url=qcom/opensource/$mod
				;;
			*)
				url=opensource/$mod
				;;
		esac
		git remote add clo/"$mod" https://git.codelinaro.org/clo/la/platform/vendor/"$url".git

		success "Add remote for target module ${mod} done."
	fi

	if [[ -d $dir && $option == "u" ]]; then
		cmd=m
	fi

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

	if [[ ! $(git diff HEAD~) ]]; then
		git reset -q --hard HEAD~
		success "HEAD resetted b'cuz empty commit for ${br}, ${mod}."
	else
		success "Import from target ${br} for target ${mod} done."
	fi
}


# Indicate module directories
indicatemodir() {
	mod="";
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
			mod=audio-kernel
			prefix=audio
			;;
		5)
			mod=camera-kernel
			prefix=camera
			;;
		6)
			mod=datarmnet
			prefix=$mod
			;;
		7)
			mod=datarmnet-ext
			prefix=$mod
			;;
		8)
			mod=dataipa
			prefix=$mod
			;;
		9)
			mod=display-drivers
			prefix=display
			;;
		10)
			mod=video-driver
			prefix=video
			;;
		11)
			dts_import
			;;
		*)
			clear
			error "Invalid target input, aborting!"
			;;
	esac

	if [ "$num" -lt '11' ]; then
		moduler
	fi
}

init() {
	if [[ -z $br ]]; then
		read -rp "Target tag / branch: " br
	fi
	for i in {1..11}; do
		num=$i;
		option=1;
		cmd=s;
		indicatemodir
	done
}

br=$1
init
