#!/bin/bash

#########################    CONFIGURATION    ##############################

# User details
KBUILD_USER="$USER"
KBUILD_HOST=$(uname -n)

############################################################################

########################   DIRECTORY PATHS   ###############################

# Kernel Directory
KERNEL_DIR=$(pwd)

# Propriatary Directory (default paths may not work!)
PRO_PATH="$KERNEL_DIR/.."

# Toolchain Directory
TLDR="$PRO_PATH/toolchains"

# Anykernel Directories
AK3_DIR="$PRO_PATH/AnyKernel3"
AKVDR="$AK3_DIR/modules/vendor/lib/modules"
AKVRD="$AK3_DIR/vendor_ramdisk/lib/modules"

# Device Tree Blob Directory
DTB_PATH="$KERNEL_DIR/work/arch/arm64/boot/dts"
DTBO_PATH="$KERNEL_DIR/work/arch/arm64/boot"

############################################################################

###############################   COLORS   #################################

R='\033[1;31m'
G='\033[1;32m'
B='\033[1;34m'
W='\033[1;37m'

############################################################################

################################   MISC   ##################################

# functions
error()
{
	echo -e ""
	echo -e "$R ${FUNCNAME[0]}: $W" "$@"
	echo -e ""
	exit 1
}

success()
{
	echo -e ""
	echo -e "$G ${FUNCNAME[1]}: $W" "$@"
	echo -e ""
	exit 0
}

inform()
{
	if [[ $SILENCE != 1 || $* =~ "--force" ]]; then
		echo -e ""
		echo -e "$B ${FUNCNAME[1]}: $W" "$@" "$G" | sed 's/--force//'
		echo -e ""
	else
		echo -e "$G"
	fi
}

muke()
{
	if [[ -z $COMPILER || -z $COMPILER32 ]]; then
		error "Compiler is missing"
	fi
	make "$@" "${MAKE_ARGS[@]}"
}

usage()
{
	inform " ./compile.sh <arg>
		--compiler   Sets the compiler to be used.
		--compiler32 Sets the 32bit compiler to be used,
					 (defaults to clang).
		--device     Sets the device for kernel build.
		--clean      Clean up build directory before running build,
					 (default behaviour is incremental).
		--dtbs       Builds dtbs, dtbo & dtbo.img.
		--dtb_zip    Builds flashable zip with dtbs, dtbo.
		--obj        Builds specified objects.
		--regen      Regenerates defconfig
		--log        Builds logs saved to log.txt in current dir.
		--silence    Silence shell output of Kbuild".
	exit 2
}

############################################################################

compiler_setup()
{
	############################  COMPILER SETUP  ##############################
	# default to clang
	CC='clang'
	C_PATH="$TLDR/$CC"
	CROSS_COMPILE="aarch64-linux-gnu-"
	LLVM_PATH="$C_PATH/bin"

	# Just override the existing declarations
	if [[ $COMPILER == gcc ]]; then
		CC='aarch64-elf-gcc'
		C_PATH="$TLDR/gcc-arm64"
		CROSS_COMPILE="aarch64-elf-"
	fi

	C_NAME=$("$C_PATH"/bin/$CC --version | head -n 1 | perl -pe 's/\(http.*?\)//gs')
	if [[ $COMPILER32 == "gcc" || $COMPILER == "gcc" ]]; then
		MAKE_ARGS+=("CC_COMPAT=$TLDR/gcc-arm/bin/arm-eabi-gcc" "CROSS_COMPILE_COMPAT=$TLDR/gcc-arm/bin/arm-eabi-")
		C_NAME_32=$($(echo "${MAKE_ARGS[@]}" | sed s/' '/'\n'/g | grep CC_COMPAT | cut -c 11-) --version | head -n 1)
	else
		MAKE_ARGS+=("CROSS_COMPILE_COMPAT=arm-linux-gnueabi-")
		C_NAME_32="$C_NAME"
	fi

	MAKE_ARGS+=("O=work" "ARCH=arm64" "BRAND_SHOW_FLAG=realme"
		"CROSS_COMPILE=$CROSS_COMPILE"
		"DTC_FLAGS+=-q" "DTC_EXT=$(which dtc)"
		"LLVM_IAS=1" "LLVM=1" "CC=$CC"
		"HOSTLD=ld.lld"	"PATH=$C_PATH/bin:$PATH"
		"KBUILD_BUILD_USER=$KBUILD_USER" "KBUILD_BUILD_HOST=$KBUILD_HOST"
		"$(head -1 build.config.common)" "$(head -2 build.config.common | tail -1)")
	############################################################################
}

config_generator()
{
	#########################  .config GENERATOR  ############################
	if [[ -z $CODENAME ]]; then
		error 'Codename not present connot proceed'
		exit 1
	fi

	DFCF="vendor/${CODENAME}-${SUFFIX}_defconfig"
	if [[ ! -f arch/arm64/configs/$DFCF ]]; then
		inform "Generating defconfig"

		export "${MAKE_ARGS[@]}" "TARGET_BUILD_VARIANT=user"

		bash scripts/gki/generate_defconfig.sh lahaina-qgki_defconfig vendor/lahaina_QGKI.config vendor/debugfs.config vendor/oplus_QGKI.config
		muke "$DFCF" vendor/lahaina_QGKI.config vendor/debugfs.config vendor/oplus_QGKI.config savedefconfig
		cat work/defconfig >arch/arm64/configs/"$DFCF"
	else
		inform "Generating .config"

		# Make .config
		muke "$DFCF" savedefconfig
	fi
	if [[ $TEST == "1" ]]; then
		./scripts/config --file work/.config -d CONFIG_LTO_CLANG
		./scripts/config --file work/.config -d CONFIG_HEADERS_INSTALL
	fi
	############################################################################
}

config_regenerator()
{
	########################  DEFCONFIG REGENERATOR  ###########################
	config_generator

	inform "Regenerating defconfig"

	cat work/defconfig >arch/arm64/configs/"$DFCF"

	success "Regeneration completed"
	############################################################################
}

obj_builder()
{
	##############################  OBJ BUILD  #################################
	if [[ $OBJ == "" ]]; then
		error "obj not defined"
	fi

	config_generator

	inform "Building $OBJ"
	if [[ $OBJ =~ "defconfig" ]]; then
		muke "$OBJ"
	else
		muke -j"$(nproc)" INSTALL_HDR_PATH="headers" "$OBJ"
	fi
	if [[ $TEST == "1" ]]; then
		rm -rf arch/arm64/configs/vendor/lahaina-${SUFFIX}_defconfig
	fi
	if [[ $DTB_ZIP != "1" ]]; then
		exit 0
	fi
	############################################################################
}

dtb_zip()
{
	##############################  DTB BUILD  #################################
	obj_builder
	source work/.config
	if [[ ! -d $AK3_DIR ]]; then
		error 'Anykernel not present cannot zip'
	fi
	if [[ ! -d "$KERNEL_DIR/out" ]]; then
		mkdir "$KERNEL_DIR"/out
	fi
	mv -f "$DTBO_PATH"/*.img "$AK3_DIR"
	find "$DTB_PATH"/vendor/*/* -name '*.dtb' -exec cat {} + > "$AK3_DIR"/dtb
	cd "$AK3_DIR" || exit
	make zip VERSION="$(echo "$CONFIG_LOCALVERSION" | cut -c 8-)-dtbs-only"
	cp ./*-signed.zip "$KERNEL_DIR"/out
	make clean
	cd "$KERNEL_DIR" || exit
	success "dtbs zip built"
	############################################################################
}

kernel_builder()
{
	##################################  BUILD  #################################
	if [[ $BUILD == "clean" ]]; then
		inform "Cleaning work directory, please wait...."
		muke -s clean mrproper distclean
	fi

	config_generator

	# Build Start
	BUILD_START=$(date +"%s")

	source work/.config
	MOD_NAME="$(muke kernelrelease -s)"
	KERNEL_VERSION=$(echo "$MOD_NAME" | cut -c -7)

	inform --force "
	*************Build Triggered*************

	CI: $KBUILD_HOST
	Core count: $(nproc)
	Device: $DEVICENAME
	Codename: $CODENAME
	Compiler: $C_NAME
	Compiler_32: $C_NAME_32
	Kernel Name: $MOD_NAME
	Linux Version: $KERNEL_VERSION
	Build Date: $(date +"%Y-%m-%d %H:%M")

	*****************************************
	"

	# Compile
	if [[ $LOG != 1 ]]; then
		muke -j"$(nproc)"
	else
		muke -j"$(nproc)" 2>&1 | tee log.txt
	fi

	if [[ $CONFIG_MODULES == "y" ]]; then
		muke -j"$(nproc)" \
			'modules_install' \
			INSTALL_MOD_STRIP=1 \
			INSTALL_MOD_PATH="modules"
	fi

	# Build End
	BUILD_END=$(date +"%s")

	DIFF=$(("$BUILD_END" - "$BUILD_START"))

	zipper
	############################################################################
}

zipper()
{
	####################################  ZIP  #################################
	TARGET="arch/arm64/boot/Image"

	if [[ ! -f $KERNEL_DIR/work/$TARGET ]]; then
		error 'Kernel image not found'
	fi
	if [[ ! -d $AK3_DIR ]]; then
		error 'Anykernel not present cannot zip'
	fi
	if [[ ! -d "$KERNEL_DIR/out" ]]; then
		mkdir "$KERNEL_DIR"/out
	fi

	# Making sure everything is ok before making zip
	cd "$AK3_DIR" || exit
	make clean
	cd "$KERNEL_DIR" || exit

	mv -f "$KERNEL_DIR"/work/"$TARGET" "$DTBO_PATH"/*.img "$AK3_DIR"
        find "$DTB_PATH"/vendor/*/* -name '*.dtb' -exec cat {} + > "$AK3_DIR"/dtb
	if [[ $CONFIG_MODULES == "y" ]]; then
		MOD_PATH="work/modules/lib/modules/$MOD_NAME"
		sed -i 's/\(kernel\/[^: ]*\/\)\([^: ]*\.ko\)/\/vendor\/lib\/modules\/\2/g' "$MOD_PATH"/modules.dep
		sed -i 's/.*\///g' "$MOD_PATH"/modules.order
		if [[ $DRM_VENDOR_MODULE == "1" ]]; then
			DRM_AS_MODULE=1
			if [ ! -d "$AK3_DIR"/vendor_ramdisk/lib/modules/ ]; then
				VENDOR_RAMDISK_CREATE=1
				mkdir -p "$AK3_DIR"/vendor_ramdisk/lib/modules/
			fi
			mv "$(find "$MOD_PATH" -name 'msm_drm.ko')" "$AKVRD"
			grep drm "$MOD_PATH/modules.alias" >"$AKVRD"/modules.alias
			grep drm "$MOD_PATH/modules.dep" | sed 's/^........//' >"$AKVRD"/modules.dep
			grep drm "$MOD_PATH/modules.softdep" >"$AKVRD"/modules.softdep
			grep drm "$MOD_PATH/modules.order" >"$AKVRD"/modules.load
			sed -i s/split_boot/dump_boot/g "$AK3_DIR"/anykernel.sh
		fi
		# shellcheck disable=SC2046
		# cp breaks with advised follow up
		cp $(find "$MOD_PATH" -name '*.ko') "$AKVDR"/
		cp "$MOD_PATH"/modules.{alias,dep,softdep} "$AKVDR"/
		cp "$MOD_PATH"/modules.order "$AKVDR"/modules.load
	fi

	LAST_COMMIT=$(git show -s --format=%s)
	LAST_HASH=$(git rev-parse --short HEAD)

	cd "$AK3_DIR" || exit

	make zip VERSION="$(echo "$CONFIG_LOCALVERSION" | cut -c 8-)" CUSTOM="$LAST_HASH"
	if [ "$DRM_AS_MODULE" = "1" ]; then
		if [ "$VENDOR_RAMDISK_CREATE" = "1" ]; then
			rm -rf "$AK3_DIR"/vendor_ramdisk/
		fi
		sed -i s/'dump_boot; # skip unpack'/'split_boot; # skip unpack'/g "$AK3_DIR"/anykernel.sh
	fi

	inform --force "
	***************AtomX-Kernel**************

	CI: $KBUILD_HOST
	Core count: $(nproc)
	Device: $DEVICENAME
	Codename: $CODENAME
	Compiler: $C_NAME
	Compiler_32: $C_NAME_32
	Kernel Name: $MOD_NAME
	Linux Version: $KERNEL_VERSION
	Build Date: $(date +"%Y-%m-%d %H:%M")

	***********last commit details***********

	Last commit (name): $LAST_COMMIT
	Last commit (hash): $LAST_HASH

	*****************************************
	"

	cp ./*-signed.zip "$KERNEL_DIR"/out

	make clean

	cd "$KERNEL_DIR" || exit

	success "build completed in $((DIFF / 60)).$((DIFF % 60)) mins"

	############################################################################
}

###############################  COMMAND_MODE  ##############################
if [[ -z $* ]]; then
	usage
fi
if [[ $* =~ "--log" ]]; then
	LOG=1
fi
if [[ $* =~ "--silence" ]]; then
	MAKE_ARGS+=("-s")
	SILENCE=1
fi
for arg in "$@"; do
	case "${arg}" in
		"--compiler="*)
			COMPILER=${arg#*=}
			COMPILER=${COMPILER,,}
			if [[ -z $COMPILER ]]; then
				usage
				break
			fi
			;&
		"--compiler32="*)
			COMPILER32=${arg#*=}
			COMPILER32=${COMPILER32,,}
			if [[ -z $COMPILER32 ]]; then
				COMPILER32="clang"
			fi
			compiler_setup
			;;
		"--device="*)
			CODE_NAME=${arg#*=}
			case $CODE_NAME in
				lahaina)
					DEVICENAME='lahaina common qgki kernel'
					CODENAME='lahaina'
					SUFFIX='qgki'
					;;
				*)
					inform 'device not supported: fallback to manual configuration'
					read -rp 'DEVICENAME: ' DEVICENAME
					read -rp 'CODENAME: ' CODENAME
					read -rp 'SUFFIX: ' SUFFIX
					;;
			esac
			;;
		"--clean")
			BUILD='clean'
			;;
		"--test")
			TEST='1'
			CODENAME=lahaina
			;;
		"--dtb_zip")
			DTB_ZIP=1
			;&
		"--dtbs")
			OBJ=dtbs
			dtb_zip
			;;
		"--obj="*)
			OBJ=${arg#*=}
			obj_builder
			;;
		"--regen")
			config_regenerator
			;;
		"--log" | "--silence")
			;;
		*)
			usage
			;;
	esac
done
############################################################################

kernel_builder
