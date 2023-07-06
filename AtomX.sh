#!/bin/bash

#########################    CONFIGURATION    ##############################

# User details
KBUILD_USER="$USER"
KBUILD_HOST=$(uname -n)
CORES=$(nproc)
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

# Device Tree Blob Directory
DTB_PATH="$KERNEL_DIR/work/arch/arm64/boot/dts/vendor/qcom"

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
	echo -e ""
	echo -e "$B ${FUNCNAME[1]}: $W" "$@" "$G"
	echo -e ""
}

muke()
{
	if [[ -z $COMPILER || -z $COMPILER32 ]]; then
		error "Compiler is missing"
	fi
	if [[ $LOG != 1 ]]; then
		make "${MAKE_ARGS[@]}" "$@"
	else
		make "$@" "${MAKE_ARGS[@]}" 2>&1 | tee log.txt
	fi
}

usage()
{
	inform " ./AtomX.sh <arg>
		--compiler   Sets the compiler to be used.
		--compiler32 Sets the 32bit compiler to be used,
					 (defaults to clang).
		--device     Sets the device for kernel build.
		--clean      Clean up build directory before running build,
					 (default behaviour is incremental).
		--dtbs       Builds dtbs, dtbo & dtbo.img.
		--dtb_zip    Builds flashable zip with dtbs, dtbo.
		--obj        Builds specified objects.
		--regen      Regenerates defconfig (savedefconfig).
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

	if [[ $COMPILER == gcc ]]; then
		CC='aarch64-elf-gcc'
		C_PATH="$TLDR/gcc-arm64"
	fi

	LLVM_PATH="$C_PATH/bin"
	C_NAME=$("$LLVM_PATH"/$CC --version | head -n 1 | perl -pe 's/\(http.*?\)//gs')
	C_NAME_32="$C_NAME"
	MAKE_ARGS=("CROSS_COMPILE_COMPAT=arm-linux-gnueabi-")

	if [[ "$COMPILER32" == "gcc" ]]; then
		MAKE_ARGS=("CC_COMPAT=$TLDR/gcc-arm/bin/arm-eabi-gcc"
				   "CROSS_COMPILE_COMPAT=$TLDR/gcc-arm/bin/arm-eabi-")
		C_NAME_32=$($(echo "${MAKE_ARGS[0]}" | cut -f2 -d"=") --version | head -n 1)
	fi

	MAKE_ARGS+=("O=work"
		"ARCH=arm64"
		"DTC_EXT=$(which dtc)"
		"LLVM=1"
		"LLVM_IAS=1"
		"-j"$CORES""
		"HOSTLD=ld.lld" "CC=$CC"
		"PATH=$C_PATH/bin:$PATH"
		"INSTALL_HDR_PATH="headers""
		"KBUILD_BUILD_USER=$KBUILD_USER"
		"KBUILD_BUILD_HOST=$KBUILD_HOST"
		"CROSS_COMPILE=aarch64-linux-gnu-"
		"LD_LIBRARY_PATH=$C_PATH/lib:$LD_LIBRARY_PATH"
		"$(head -1 build.config.common)")
	############################################################################
}

config_generator()
{
	#########################  .config GENERATOR  ############################
	if [[ -z $CODENAME ]]; then
		error 'Codename not present connot proceed'
		exit 1
	fi
	if [[ -z $BASE ]]; then
		DFCF="vendor/${CODENAME}-${SUFFIX}_defconfig"
	else
		DFCF="vendor/${BASE}-${SUFFIX}_defconfig"
	fi

	if [[ ! -f arch/arm64/configs/$DFCF ]]; then
		# cleanup work dir as no builds
		rm -rf work

		inform "Generating defconfig"

		export "${MAKE_ARGS[@]}" "TARGET_BUILD_VARIANT=user"

		if [[ -z $BASE ]]; then
			bash scripts/gki/generate_defconfig.sh "${CODENAME}-${SUFFIX}_defconfig"
			muke $DFCF vendor/lahaina_QGKI.config savedefconfig
		else
			bash scripts/gki/generate_defconfig.sh "${BASE}-${SUFFIX}_defconfig"
		fi
		muke $DFCF vendor/lahaina_QGKI.config savedefconfig
		rm -rf arch/arm64/configs/$DFCF
		mv work/defconfig arch/arm64/configs/$DFCF

		# cleanup work dir as no builds
		rm -rf work
	fi
	inform "Generating .config"

	# Make .config
	muke "$DFCF"

	if [[ ! -z $BASE ]] && [[ $GENERATE != 1 ]]; then
		muke "$DFCF" "vendor/${CODENAME}-fragment.config"
	fi

	############################################################################
}

config_regenerator()
{
	########################  DEFCONFIG REGENERATOR  ###########################
	config_generator

	inform "Regenerating defconfig"

	muke savedefconfig

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
	muke "$OBJ"
	if [[ "$DTB_ZIP" != "1" ]]; then
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
	cp "$DTB_PATH"/*.dtb "$AK3_DIR"/dtb
	cp "$DTB_PATH"/*.img "$AK3_DIR"/
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
	if [[ "$BUILD" == "clean" ]]; then
		inform "Cleaning work directory, please wait...."
		muke -s clean mrproper distclean
	fi

	config_generator

	# Build Start
	BUILD_START=$(date +"%s")

	source work/.config
	MOD_NAME="$(muke kernelrelease -s)"
	KERNEL_VERSION=$(echo "$MOD_NAME" | cut -c -7)

	inform "
	*************Build Triggered*************
	Date: $(date +"%Y-%m-%d %H:%M")
	Linux Version: $KERNEL_VERSION
	Kernel Name: $MOD_NAME
	Device: $DEVICENAME
	Codename: $CODENAME
	Compiler: $C_NAME
	Compiler_32: $C_NAME_32
	"

	# Compile
	muke
	if [[ $CONFIG_MODULES == "y" ]]; then
		muke 'modules_install' INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH="modules"
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
	TARGET="$(muke image_name -s)"

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

	cp "$KERNEL_DIR"/work/"$TARGET" "$AK3_DIR"
	cp "$DTB_PATH"/*.dtb "$AK3_DIR"/dtb
	cp "$DTB_PATH"/*.img "$AK3_DIR"/
	if [[ $CONFIG_MODULES == "y" ]]; then
		MOD_PATH="work/modules/lib/modules/$MOD_NAME"
		sed -i 's/\(kernel\/[^: ]*\/\)\([^: ]*\.ko\)/\/vendor\/lib\/modules\/\2/g' "$MOD_PATH"/modules.dep
		sed -i 's/.*\///g' "$MOD_PATH"/modules.order
		cp  $(find "$MOD_PATH" -name '*.ko') "$AKVDR"/
		cp "$MOD_PATH"/modules.{alias,dep,softdep} "$AKVDR"/
		cp "$MOD_PATH"/modules.order "$AKVDR"/modules.load
	fi

	LAST_COMMIT=$(git show -s --format=%s)
	LAST_HASH=$(git rev-parse --short HEAD)

	cd "$AK3_DIR" || exit

	make zip CODENAME=$CODENAME VERSION="$(echo "$CONFIG_LOCALVERSION" | cut -c 8-)"

	inform "
	*************AtomX-Kernel*************
	Linux Version: $KERNEL_VERSION
	CI: $KBUILD_HOST
	Core count: $CORES
	Compiler: $C_NAME
	Compiler_32: $C_NAME_32
	Device: $DEVICENAME
	Codename: $CODENAME
	Build Date: $(date +"%Y-%m-%d %H:%M")
	Build Type: $BUILD_TYPE

	-----------last commit details-----------
	Last commit (name): $LAST_COMMIT

	Last commit (hash): $LAST_HASH
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
if [[ "$*" =~ "--log" ]]; then
	LOG=1
fi
if [[ "$*" =~ "--silence" ]]; then
	MAKE_ARGS+=("-s")
fi
for arg in "$@"; do
	case "${arg}" in
		"--compiler="*)
			COMPILER=${arg#*=}
			COMPILER=${COMPILER,,}
			if [[ -z "$COMPILER" ]]; then
				usage
				break
			fi
			;&
		"--compiler32="*)
			COMPILER32=${arg#*=}
			COMPILER32=${COMPILER32,,}
			if [[ -z "$COMPILER32" ]]; then
				COMPILER32="clang"
			fi
			compiler_setup
			;;
		"--device="*)
			CODE_NAME=${arg#*=}
			case $CODE_NAME in
				lisa)
					DEVICENAME='Xiaomi 11 lite 5G NE'
					CODENAME='lisa'
					BASE='xiaomi'
					SUFFIX='qgki'
					TARGET='Image'
					;;
				redwood)
					DEVICENAME='Poco X5 Pro 5G'
					CODENAME='redwood'
					BASE='xiaomi'
					SUFFIX='qgki'
					TARGET='Image'
					;;
				*)
					error 'device not supported'
					;;
			esac
			;;
		"--clean")
			BUILD='clean'
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
			GENERATE=1
			config_regenerator
			;;
	esac
done
############################################################################

kernel_builder
