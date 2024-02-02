#!/bin/bash
#
#	Build to lahaina - ./compile.sh --device=lahaina --compiler=clang
# 	or
#	./compile.sh --device=lahaina --compiler=gcc
#	or
#	./compile.sh --device=lahaina --compiler=clang --compiler32=gcc
#
#	Android Kernel Build Script to k5.x
#

############################################################################

# Setup colour for the script
blue='\033[0;34m'
yellow='\033[0;33m'
white='\033[0m'
red='\033[0;31m'
green='\e[0;32m'
magenta='\033[1;35m'
lgreen='\e[92m'
cyan='\033[0;36m'
purple='\033[0;35m'
pink='\033[38;5;206m'
orange_yellow='\033[38;5;214m'
greenish_yellow='\033[38;5;190m'
blink_red='\033[05;31m'
blink_green='\033[1;32;5m'
blink_yellow='\033[1;33;5m'
reset='\e[0m'

##------------------------------------------------------##

# Function to show an informational message
msg() {
    echo -e "\e[1;32m$*\e[0m"
}

err() {
    echo -e "\e[1;41m$*\e[0m"
    exit 1
}

##------------------------------------------------------##

# Timeout
function countdown() {
    for ((i = $1; i > 0; i--)); do
        echo "Countdown: $i"
        sleep 1
    done
}

##------------------------------------------------------##

# Get Linux distro and version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    OS=$(uname -s)
    VER=$(uname -r)
fi

echo $OS $VER

##------------------------------------------------------##

# Check if is Legendary!
if [[ "$OS" == *"Tumbleweed"* ]]; then
    echo -e "${magenta} << You are LEGENDARY! >> ${white}"
else
    echo -e "${lgreen} << May the force be with you! >> ${reset}"
fi

##------------------------------------------------------##

# Check if a good linux is being used
if [[ "$OS" == *"SUSE"* ]] || [[ "$OS" == *"Regata"* ]] || [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Nobara"* ]] || [[ "$OS" == *"Ultramarine"* ]] || [[ "$OS" == *"Rocky"* ]] || [[ "$OS" == *"Arch"* ]]; then
    echo -e "${cyan} << Congratulations! You are using a decent Linux >> ${white}"
else
    echo -e "${red} << Danger detected! You are using MEME linux. Get out of this garbage as soon as possible >> ${white}"
fi

##------------------------------------------------------##

# Set Brazil timezone
export TZ=America/Sao_Paulo

##------------------------------------------------------##

# Setup the build environment if OS is openSUSE
AKHILNARANG="environment"
msg $green "|| Clone & Build environment ||" $white
if [[ "$OS" == *"SUSE"* ]] || [[ "$OS" == *"Regata"* ]]; then
    echo -e "${blue} << Environment to openSUSE >> ${white}"
    # Check if $DIR exists or not
    if [[ ! -d "$AKHILNARANG" ]]; then
        echo -e "$yellow $AKHILNARANG not found, downloading... $white"
        git clone --depth=1 https://github.com/TogoFire/scripts -b akh ${AKHILNARANG}
        cd "${AKHILNARANG}" && bash setup/opensuse.sh
        cd ..
    else
        echo -e "$yellow $AKHILNARANG found, skipping step $white"
    fi
fi

# Setup the build environment if OS is Fedora
if [[ "$OS" == *"Fedora"* ]] || [[ "$OS" == *"Nobara"* ]] || [[ "$OS" == *"Ultramarine"* ]] || [[ "$OS" == *"Rocky"* ]]; then
    echo -e "${blue} << Environment to Fedora >> ${white}"
    # Check if $DIR exists or not
    if [[ ! -d "$AKHILNARANG" ]]; then
        echo -e "$yellow $AKHILNARANG not found, downloading... $white"
        git clone --depth=1 https://github.com/TogoFire/scripts -b akh ${AKHILNARANG}
        cd "${AKHILNARANG}" && bash setup/fedora.sh
        cd ..
    else
        echo -e "$yellow $AKHILNARANG found, skipping step $white"
    fi
fi

# Setup the build environment if OS is Arch
if [[ "$OS" == *"Arch"* ]] || [[ "$OS" == *"Manjaro"* ]] || [[ "$OS" == *"Endeavour"* ]] || [[ "$OS" == *"Garuda"* ]]; then
    echo -e "${blue} << Environment to Arch >> ${white}"
    # Check if $DIR exists or not
    if [[ ! -d "$AKHILNARANG" ]]; then
        echo -e "$yellow $AKHILNARANG not found, downloading... $white"
        git clone --depth=1 https://github.com/akhilnarang/scripts ${AKHILNARANG}
        cd "${AKHILNARANG}" && bash setup/arch-manjaro.sh
        cd ..
    else
        echo -e "$yellow $AKHILNARANG found, skipping step $white"
    fi
fi

# Setup the build environment if OS is MEME
if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Mint"* ]] || [[ "$OS" == *"Debian"* ]] || [[ "$OS" == *"Pop"* ]] || [[ "$OS" == *"Zorin"* ]] || [[ "$OS" == *"Elementary"* ]] || [[ "$OS" == *"Mx"* ]] || [[ "$OS" == *"antiX"* ]] || [[ "$OS" == *"Sparky"* ]] || [[ "$OS" == *"Parrot"* ]] || [[ "$OS" == *"Deepin"* ]] || [[ "$OS" == *"Kali"* ]] || [[ "$OS" == *"KDE"* ]] || [[ "$OS" == *"Lite"* ]]; then
    echo -e "${pink} << Environment to MEME Linux >> ${white}"
    # Check if $DIR exists or not
    if [[ ! -d "$AKHILNARANG" ]]; then
        echo -e "$yellow $AKHILNARANG not found, downloading... $white"
        git clone --depth=1 https://github.com/TogoFire/scripts -b akh ${AKHILNARANG}
        cd "${AKHILNARANG}" && bash setup/android_build_env.sh
        cd ..
    else
        echo -e "$yellow $AKHILNARANG found, skipping step $white"
    fi
fi

##------------------------------------------------------##

# Clone toolchain
msg $green "|| Cloning Toolchain ||" $white
    echo -e "$blue << Toolchain download... >> $white"
	# Dir clang
	CLANG_VERSION=clang
	# Directory
	dirtoolchains="toolchains"
	# Check if the directory exists and create it if not
	if [ ! -d "$dirtoolchains" ]; then
	mkdir -p "$dirtoolchains"
	echo "Directory '$dirtoolchains' created successfully."
	else
	echo "Directory '$dirtoolchains' already exists."
	fi
	cd toolchains
	
		# GCC EVA
		echo -e "$blue << GCC download... >> $white"
		# Dir to GCC
		dirgcc=("gcc-arm" "gcc-arm64")

		# Check dir
		if [ ! -d "$dirgcc" ]; then
		# Files to download
		files=("eva-gcc-arm" "eva-gcc-arm64")

		# Base URL of the repository
		repo_url="https://github.com/mvaisakh/gcc-build/releases/download/"

		# Function to get the last 7 days in DDMMYYYY format
		get_last_60_days() {
			local today=$(date +%Y%m%d)
			for (( i=0; i<=59; i++ )); do
			local date=$(date -d "$today - $i days" +%d%m%Y)
			echo "$date"
			done
		}

		# Iterate over files
		for file in "${files[@]}"; do
			# Download only if the file is not already downloaded (assuming filenames are unique)
			if [ ! -f "$file.xz" ]; then
			for date in $(get_last_60_days); do
				url="$repo_url$date/$file-$date.xz"
				echo "Downloading: $url"

				# Download file
				# Via aria2 (universal)
				aria2c -x 16 -s 16 -o "$file-$date.xz" "$url"
				# .deb shit
				#wget -q -O "$file-$date.xz" --show-progress "$url"

			# Download with progress bar and error handling
			if aria2c -x 16 -s 16 -o "$file-$date.xz" "$url" && [ $? -eq 0 ]; then
				echo "Download successful: $file-$date.xz"

				# Extract the file directly to the current directory
				tar xf "$file-$date.xz"

				# Extract the file to the corresponding directory (optional)
				# tar xf "$file-$date.xz" -C toolchains

				# Remove the .xz file
				#rm "$file-$date.xz"

				# **Additional check: Remove files with .1.xz extension**
				find . -name "$file*.1.xz" -delete

				# Exit the loop after successful download (assuming only gcc-arm or gcc-arm64 is needed)
				break
			else
				echo "Download failed: $url"
				# Add actions for failures (e.g., remove incomplete file, log error)
				rm -f "$file-$date.xz"
			fi
			done
		fi
		done
		else
		echo "Directory '$dirgcc' already exists."
		fi

	if [[ ! -d "$CLANG_VERSION" ]]; then
		# Weebx Clang
		echo -e "$blue << Clang download... >> $white"
		wget "$(curl -s https://raw.githubusercontent.com/XSans0/WeebX-Clang/main/main/link.txt)" -O "weebx-clang.tar.gz"
		mkdir clang && tar -xf weebx-clang.tar.gz -C clang --strip-components=1 && rm -f weebx-clang.tar.gz
    else
        # Check if there is only one folder starting with "clang"
        num_dirs=$(ls -d clang* | wc -l)
        if [ $num_dirs -eq 1 ]; then
            CLANG_VERSION=$(ls -d clang*/)
            echo -e "${yellow} Clang found! Skipping step ${white}"
        fi
        # Check if there is only one folder starting with "gcc"
        num_dirs=$(ls -d gcc* | wc -l)
        if [ $num_dirs -eq 1 ]; then
            GCC_VERSION=$(ls -d gcc*/)
            echo -e "${yellow} GCC found! Skipping step ${white}"
        fi

	fi

cd ..

##------------------------------------------------------##

# Clean-up
echo -e "${orange_yellow} Clean-up ${white}"
rm -rf out/*
rm -rf work/*
rm -rf error.log
rm -rf changelog/*
rm -rf ./*.tar.gz

# Remove ak3
if [[ ! -d "AnyKernel3" ]]; then
	echo -e "${orange_yellow} AnyKernel3 directory not found. Skipping cleanup ak3. ${white}"
else
	# Move into the directory (safer than `cd` within an if statement)
	pushd AnyKernel3 >/dev/null 2>&1  # Push the directory onto the stack

	# Remove Image and dtb files with 5-second timeout and default "y"
	#if [[ -f Image || -f dtb ]]; then
		##read -r -p "Remove Image and dtb files? (y/N) " response
		#response=$(timeout 5 bash -c "read -r -p 'Remove Image and dtb files? (y/N) [y] ' ; echo \$REPLY")
	#if [[ "$response" =~ ^([Yy])$ ]]; then
		rm -f Image dtb
	#else
	#	echo "Image and dtb files left untouched."
		#fi
	#fi

	# Remove Image and dtb files without confirmation
	rm -f Image dtb

	# Remove all .img and .zip files
	rm -f *.img *.zip

	# Move back to the previous directory
	popd >/dev/null 2>&1  # Pop the directory from the stack
fi

##------------------------------------------------------##

# Clone AnyKernel3
ANYKERNEL3_VERSION="AnyKernel3"
msg $green "|| Cloning AnyKernel3 ||" $white

# Check if AnyKernel directory exists
if [[ ! -d "$ANYKERNEL3_VERSION" ]]; then
    echo -e "$yellow $ANYKERNEL3_VERSION not found, downloading... $white"

# Display options and accept choice from user
echo -e "${magenta}\n👉 Choose AnyKernel version: ${white}"
echo -e "${blue}1. McQuaid"
echo "2. NetHunter"
echo "3. KernelSU"
echo "4. GCC"
echo "5. McQ-Legacy"
echo "6. McQ-Nethunter-Legacy"
echo -e "7. McQ-KSU-Legacy\n${white}"

#if [[ $GCC_VERSION =~ "gcc" ]]; then
#        choice=4
#        echo -e "$lgreen Ak3 choice to 4. $white"
#    else
read -t 5 -p "Enter your choice [1-7]: " choice || {
    echo -e "$cyan Timeout of 5 seconds reached. No input received. $white"
    echo -e "$lgreen Ak3 choice to 1. $white"
    choice=1
    }
#fi

    case $choice in
        1)
            git clone --depth=1 https://github.com/dev-sm8350/AnyKernel3 -b McQ "${ANYKERNEL3_VERSION}"
            ;;
        2)
            git clone --depth=1 https://github.com/dev-sm8350/AnyKernel3 -b McQ-Nethunter "${ANYKERNEL3_VERSION}"
            ;;
        3)
            git clone --depth=1 https://github.com/dev-sm8350/AnyKernel3 -b McQ-KSU "${ANYKERNEL3_VERSION}"
            ;;
        4)
            git clone --depth=1 https://github.com/dev-sm8350/AnyKernel3 -b McQ-GCC "${ANYKERNEL3_VERSION}"            
            ;;
        5)
            git clone --depth=1 https://github.com/dev-sm8350/AnyKernel3 -b McQ-Legacy "${ANYKERNEL3_VERSION}"            
            ;;
        6)
            git clone --depth=1 https://github.com/dev-sm8350/AnyKernel3 -b McQ-Nethunter-Legacy "${ANYKERNEL3_VERSION}"
            ;;
        7)
            git clone --depth=1 https://github.com/dev-sm8350/AnyKernel3 -b McQ-KSU-Legacy "${ANYKERNEL3_VERSION}"
            ;;
        *)
            echo "Invalid choice, please try again."
            ;;
    esac

else
    echo -e "$yellow $ANYKERNEL3_VERSION found, skipping step $white"   
fi

    # Check which AnyKernel version is currently being used
    cd $ANYKERNEL3_VERSION
    
    # Get the current branch name, indicated by an asterisk (*), and extract the version number
    CURRENT_VERSION=$(git branch -a | grep '*' | awk '{print $2}' | sed 's/^[[:alpha:]]\///')
    
    if [[ -n "$CURRENT_VERSION" ]]; then
        ANYK_VERSION="$CURRENT_VERSION"
        echo -e "$greenish_yellow Currently being used Anykernel version: $ANYK_VERSION $white"
    else
        echo -e "$red Could not detect AnyKernel version! $white"
        exit 1
    fi
    cd ..

##------------------------------------------------------##

# KernelSU
# Check if AK3 is KSU version to build KernelSU
#if [[ "$ANYK_VERSION" == *"KSU"* ]]; then
#    sed -i 's/# CONFIG_KSU is not set/CONFIG_KSU=y/' arch/arm64/configs/vendor/lahaina-qgki_defconfig
#    echo -e "$cyan KernelSU option selected and enabled to be built! $white"
#fi

##------------------------------------------------------##

# CHANGELOG
# Create a filename for our changelog in a changelog directory
CHANGELOG_DIR="changelog"
CHANGELOG_FILE="$CHANGELOG_DIR/kernel-changelog.txt"

# Check if the changelog directory exists, and create it if it doesn't
if [ ! -d "$CHANGELOG_DIR" ]; then
  mkdir "$CHANGELOG_DIR"
fi

# Use git log to get the most recent kernel commits
git log -n 350 --pretty=format:"%h - %s (%an)" > $CHANGELOG_FILE

# Print the location of the changelog file
echo -e "${purple} Changelog saved to $CHANGELOG_FILE ${white}"

# Add commit names to the changelog file
sed -i -e "s/^/- /" $CHANGELOG_FILE

##------------------------------------------------------##

############################################################################

#########################    CONFIGURATION    ##############################

# User details
KBUILD_USER="TogoFire"
KBUILD_HOST=SUSE
#KBUILD_USER="$USER"
#KBUILD_HOST=$(uname -n)

############################################################################


########################   DIRECTORY PATHS   ###############################

# Kernel Directory
KERNEL_DIR=$(pwd)

# Propriatary Directory (default paths may not work!)
PRO_PATH="$KERNEL_DIR/.."

# Toolchain Directory
#TLDR="$PRO_PATH/toolchains"
TLDR="$(pwd)/toolchains"

# Anykernel Directories
#AK3_DIR="$PRO_PATH/AnyKernel3"
AK3_DIR="$(pwd)/AnyKernel3"
AKVDR="$AK3_DIR/modules/vendor/lib/modules"
AKVRD="$AK3_DIR/vendor_ramdisk/lib/modules"

# Confirm that the path to AnyKernel3
echo $AK3_DIR

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

setup_kernelsu() {
	inform "KernelSU setup"
    cd $KERNEL_DIR || exit
    curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main
    git apply ../ksu.patch
}

compiler_setup()
{
	############################  COMPILER SETUP  ##############################
	# default to clang
	CC='clang'
	#C_PATH="$TLDR/$CC"
	C_PATH="$(pwd)/toolchains/clang"
	CROSS_COMPILE="aarch64-linux-gnu-"
	LLVM_PATH="$C_PATH/bin"

	# Just override the existing declarations
	if [[ $COMPILER == gcc ]]; then
		CC='aarch64-elf-gcc'
		C_PATH="$(pwd)/toolchains/gcc-arm64"
		CROSS_COMPILE="aarch64-elf-"
	fi

	C_NAME=$("$C_PATH"/bin/$CC --version | head -n 1 | perl -pe 's/\(http.*?\)//gs')
	if [[ $COMPILER32 == "gcc" || $COMPILER == "gcc" ]]; then
		MAKE_ARGS+=("CC_COMPAT=$TLDR/gcc-arm/bin/arm-eabi-gcc" "CROSS_COMPILE_COMPAT=$TLDR/gcc-arm/bin/arm-eabi-" "GCC_LTO=1" "GRAPHITE=1")
		C_NAME_32=$($(echo "${MAKE_ARGS[@]}" | sed s/' '/'\n'/g | grep CC_COMPAT | cut -c 11-) --version | head -n 1)
	else
		MAKE_ARGS+=("CROSS_COMPILE_COMPAT=arm-linux-gnueabi-")
		C_NAME_32="$C_NAME"
	fi

	if [[ $COMPILER == "clang" || $COMPILER == "clang" ]]; then
		MAKE_ARGS+=("LLVM_IAS=1" "LLVM=1" )
	fi

	MAKE_ARGS+=("O=work" "ARCH=arm64"
		"CROSS_COMPILE=$CROSS_COMPILE"
		"DTC_FLAGS+=-q" "DTC_EXT=$(which dtc)"
		"CC=$CC"
		"HOSTLD=ld.lld" "PATH=$C_PATH/bin:$PATH"
		"KBUILD_BUILD_USER=$KBUILD_USER" "KBUILD_BUILD_HOST=$KBUILD_HOST"
		"$(head -1 build.config.common)" "$(head -2 build.config.common | tail -1)")

	# Get log
	CREATE_LOG=0
	if [ "$CREATE_LOG" -eq 1 ]; then
		MAKE_LOG="2>&1 | tee error.log"
		make "${MAKE_ARGS[@]}" $MAKE_LOG
	fi
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
	#make clean
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

	# Make ZIP
	MOBILEDEVICE='op9x'
	BUILD_TIME=$(date +"%d%m%Y-%H%M")
	ZIPSIGNER_JAR=zipsigner-3.0.jar

	# Create zip file with version, release, device, and timestamp
	zip -r9 "${ANYK_VERSION}"-r"${RELEASE}"-"${MOBILEDEVICE}"-"${BUILD_TIME}".zip ./*

	# Sign the zip file
	java -jar $ZIPSIGNER_JAR "${ANYK_VERSION}"-r"${RELEASE}"-"${MOBILEDEVICE}"-"${BUILD_TIME}".zip "${ANYK_VERSION}"-r"${RELEASE}"-"${MOBILEDEVICE}"-"${BUILD_TIME}"-signed.zip

	# Success message
	echo -e "  Success! Ak3 zip built and signed"

	# Make zip for different target (optional, keep if needed)
	make zip VERSION="$(echo "$CONFIG_LOCALVERSION" | cut -c 8-)" CUSTOM="$LAST_HASH"
	if [ "$DRM_AS_MODULE" = "1" ]; then
	if [ "$VENDOR_RAMDISK_CREATE" = "1" ]; then
		rm -rf "$AK3_DIR"/vendor_ramdisk/
	fi
	sed -i s/'dump_boot; # skip unpack'/'split_boot; # skip unpack'/g "$AK3_DIR"/anykernel.sh
	fi

	# Info ZIP
	echo -e "The kernel has successfully been compiled and can be found in $(pwd)/${greenish_yellow}${ANYK_VERSION}-r${RELEASE}-${MOBILEDEVICE}-${BUILD_TIME}-signed.zip $white"

	# Calculate checksums for the signed zip
	SHA=$(shasum "$(pwd)"/"${ANYK_VERSION}"-r"${RELEASE}"-"${MOBILEDEVICE}"-"${BUILD_TIME}"-signed.zip | cut -f 1 -d '/')
	MD5=$(md5sum "$(pwd)"/"${ANYK_VERSION}"-r"${RELEASE}"-"${MOBILEDEVICE}"-"${BUILD_TIME}"-signed.zip | cut -f 1 -d '/')
	echo -e "  MD5 Checksum : $MD5 $white"
	echo -e "  SHA1 Checksum : $SHA $white"

    # Upload to mega
    # Asks the user if they want to upload the file
    echo -e "$yellow \n👉 Do you want to upload the file to megaupload? (y/n) $white"
    read -t 5 -p "$(tput setaf 171) Enter your answer: " answer || {
    echo -e "$cyan Timeout of 5 seconds reached. No input received. $white"
    echo -e "$lgreen Setting choice to n. $white"
    answer=n
    }

    if [[ $answer == "y" ]]; then
    # Asks the user for their email and password
    echo -e "$blue Enter your email address: $white"
    read -p "$(tput setaf 171) Email: " email
    echo -e "$blue Enter your password: $white"
    read -s -p "$(tput setaf 171) Password: " password

    # Uploads the file
    # megaput $(pwd)/${ANYK_VERSION}-r${RELEASE}-${MOBILEDEVICE}-${BUILD_TIME}.zip -u $email -p $password
	megaput $(pwd)/${ANYK_VERSION}-r${RELEASE}-${MOBILEDEVICE}-${BUILD_TIME}-signed.zip -u $email -p $password
    countdown 3
    echo -e "$reset 👍 $white"
    fi

	inform --force "
	***************McQuaid-Kernel**************

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

	#cp ./*-signed.zip "$KERNEL_DIR"/out

	#make clean

	cd "$KERNEL_DIR" || exit
	
	success "Build completed in $((DIFF / 60)).$((DIFF % 60)) mins"

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
