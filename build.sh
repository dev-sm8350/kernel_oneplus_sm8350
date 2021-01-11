#!/usr/bin/env bash

# Android Kernel Build Script to k5.4
# ./build.sh 
#

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
if [[ -z $(ls -A | grep -E 'clang-neutron|clang-weebx|clang-greenforce|clang-trb|clang-playground|clang-zyc|clang-llvm|gcc-eva') ]]; then
    echo -e "$yellow No existing Toolchain versions found. Proceeding to download... $white"
    read -t 5 -p "$(tput setaf 171)👉 Which version of Clang would you like to use? (1) clang-neutron, (2) clang-weebx, (3) clang-greenforce, (4) clang-trb, (5) clang-playground, (6) clang-zyc, (7) clang-llvm or (8) gcc-eva.$(tput sgr0)
    Type your answer here: " VERSION_CHOICE || {
    echo -e "$cyan Timeout of 5 seconds reached. No input received. $white"
    VERSION_CHOICE=8
    }

    if [ "$VERSION_CHOICE" = "1" ]; then
        CLANG_VERSION="clang-neutron"
    elif [ "$VERSION_CHOICE" = "2" ]; then
        CLANG_VERSION="clang-weebx"
    elif [ "$VERSION_CHOICE" = "3" ]; then
        CLANG_VERSION="clang-greenforce"
    elif [ "$VERSION_CHOICE" = "4" ]; then
        CLANG_VERSION="clang-trb"
    elif [ "$VERSION_CHOICE" = "5" ]; then
        CLANG_VERSION="clang-playground"
    elif [ "$VERSION_CHOICE" = "6" ]; then
        CLANG_VERSION="clang-zyc"
    elif [ "$VERSION_CHOICE" = "7" ]; then
        CLANG_VERSION="clang-llvm"
    elif [ "$VERSION_CHOICE" = "8" ]; then
        GCC_VERSION="gcc-eva"
    else
        echo -e "$red Please select a valid option." $white
        exit 1 # Exit script if invalid choice is made
    fi
    
    echo -e "$blue << Toolchain download... >> $white"

    if [ "$CLANG_VERSION" = "clang-neutron" ]; then
        mkdir "${CLANG_VERSION}"
        cd "${CLANG_VERSION}"
        bash <(curl -s "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman") -S
        cd ..
    elif [ "$CLANG_VERSION" = "clang-weebx" ]; then
        wget "$(curl -s https://raw.githubusercontent.com/XSans0/WeebX-Clang/main/main/link.txt)" -O "weebx-clang.tar.gz"
        mkdir clang-weebx && tar -xf weebx-clang.tar.gz -C clang-weebx --strip-components=1 && rm -f weebx-clang.tar.gz
    elif [ "$CLANG_VERSION" = "clang-greenforce" ]; then
        git clone https://gitlab.com/fadlyas07/clang-llvm.git ${CLANG_VERSION} --depth=1 --single-branch --no-tags
    elif [ "$CLANG_VERSION" = "clang-trb" ]; then 
        git clone https://gitlab.com/varunhardgamer/trb_clang.git ${CLANG_VERSION} --depth=1 --single-branch --no-tags
    elif [ "$CLANG_VERSION" = "clang-playground" ]; then 
        git clone https://gitlab.com/PixelOS-Devices/playgroundtc.git ${CLANG_VERSION} --depth=1 --single-branch --no-tags
    elif [ "$CLANG_VERSION" = "clang-zyc" ]; then
        mkdir "${CLANG_VERSION}"
        cd "${CLANG_VERSION}"
        # Get the link from the txt file
        link=$(curl -s https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-link.txt)
        # Download the file
        curl -o clang-zyc.tar.gz -L "$link"
        # Extract the file
        tar -xf clang-zyc.tar.gz
        # Remove the tarball
        rm clang-zyc.tar.gz
        cd ..
    elif [ "$CLANG_VERSION" = "clang-llvm" ]; then 
        # AOSP clang
        CURRENT_CLANG=$(curl https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+/refs/heads/master/ | grep -oE "clang-r[0-9a-f]+" | sort -u | tail -n1)
        echo -e "FETCHING $CURRENT_CLANG from AOSP..."
        git clone https://gitlab.com/Neebe3289/android_prebuilts_clang_host_linux-x86.git -b $CURRENT_CLANG ${CLANG_VERSION} --depth=1 --single-branch --no-tags
        #aria2c -q -j64 -x4 -s4 -k50M -c "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/$CURRENT_CLANG.tar.gz"
        #wget -q -c -O $CURRENT_CLANG.tar.gz "https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/$CURRENT_CLANG.tar.gz" | pv
        #mkdir -p clang-llvm && tar -xf ./*.tar.gz -C /clang-llvm && rm ./*.tar.gz && rem clang-llvm
        touch $CLANG_VERSION/bin/aarch64-linux-gnu-elfedit && chmod +x /$CLANG_VERSION/bin/aarch64-linux-gnu-elfedit
        touch $CLANG_VERSION/bin/arm-linux-gnueabi-elfedit && chmod +x /$CLANG_VERSION/bin/arm-linux-gnueabi-elfedit

        msg $green "|| Cloning Binutils ||" $white
	    git clone https://android.googlesource.com/platform/prebuilts/gas/linux-x86.git -b master gcc --depth=1 --single-branch --no-tags
        #git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git --depth=1 gcc64
		#git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git  --depth=1 gcc

	    # Toolchain Directory defaults to clang-llvm
	    TC_DIR=$KERNEL_DIR/${CLANG_VERSION}
	    GCC_DIR=$KERNEL_DIR/gcc
    elif [ "$GCC_VERSION" = "gcc-eva" ]; then
        git clone https://github.com/mvaisakh/gcc-arm.git gcc --depth=1 --single-branch --no-tags
        git clone https://github.com/mvaisakh/gcc-arm64.git ${GCC_VERSION} --depth=1 --single-branch --no-tags
    fi
    else
        if [ "$CLANG_VERSION" = "clang-neutron" ]; then
            cd "${CLANG_VERSION}"
            echo -e "$yellow $CLANG_VERSION found, checking updates & skipping step $white"
            bash <(curl -s "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman") -U
            bash <(curl -s "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman") -I
            cd ..
        fi
        # Check if there is only one folder starting with "clang-"
        num_dirs=$(ls -d clang-* | wc -l)
        if [ $num_dirs -eq 1 ]; then
            CLANG_VERSION=$(ls -d clang-*/)
            echo -e "${yellow} Clang found! Skipping step ${white}"
        fi
        # Check if there is only one folder starting with "gcc-"
        num_dirs=$(ls -d gcc-* | wc -l)
        if [ $num_dirs -eq 1 ]; then
            GCC_VERSION=$(ls -d gcc-*/)
            echo -e "${yellow} GCC found! Skipping step ${white}"
        fi

        if [ -n "$CLANG_VERSION" ] && [ -n "$GCC_VERSION" ]; then
            echo -e "$red ERROR: Multiple or no Clang/GCC versions found. Please specify which version to use." $white
            exit 1
        fi

fi
    # Show which toolchain is being used
    echo -e "${greenish_yellow} Currently using toolchain version: $CLANG_VERSION $GCC_VERSION ${white}"

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
echo -e "4. GCC\n${white}"

if [[ $GCC_VERSION =~ "gcc-eva" ]]; then
        choice=4
        echo -e "$lgreen Ak3 choice to 4. $white"
    else
read -t 5 -p "Enter your choice [1-4]: " choice || {
    echo -e "$cyan Timeout of 5 seconds reached. No input received. $white"
    echo -e "$lgreen Ak3 choice to 1. $white"
    choice=1
    }
fi

    case $choice in
        1)
            git clone --depth=1 https://github.com/dev-sm8350/AnyKernel3 -b McQuaid "${ANYKERNEL3_VERSION}"
            ;;
        2)
            git clone --depth=1 https://github.com/dev-sm8350/AnyKernel3 -b McQuaid-Nethunter "${ANYKERNEL3_VERSION}"
            ;;
        3)
            git clone --depth=1 https://github.com/dev-sm8350/AnyKernel3 -b McQuaid-KSU "${ANYKERNEL3_VERSION}"
            ;;
        4)
            git clone --depth=1 https://github.com/dev-sm8350/AnyKernel3 -b McQuaid-GCC "${ANYKERNEL3_VERSION}"            
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
if [[ "$ANYK_VERSION" == *"KSU"* ]]; then
    sed -i 's/# CONFIG_KSU is not set/CONFIG_KSU=y/' arch/arm64/configs/vendor/lahaina-qgki_defconfig
    echo -e "$cyan KernelSU option selected and enabled to be built! $white"
fi

##------------------------------------------------------##

# Nethunter | NetErnels | KSU
# Check if AK3 is Nethunter version to build Kali Nethunter
if [[ "$ANYK_VERSION" == *"Nethunter"* ]] || [[ "$ANYK_VERSION" == *"Nethunter"* ]]; then
    sed -i 's/# CONFIG_KSU is not set/CONFIG_KSU=y/' arch/arm64/configs/vendor/lahaina-qgki_defconfig
    sed -i 's/# CONFIG_NETHUNTER_SUPPORT is not set/CONFIG_NETHUNTER_SUPPORT=y/' arch/arm64/configs/vendor/lahaina-qgki_defconfig
    echo -e "$cyan Nethunter & KSU option selected and enabled to be built! $white"
fi

##------------------------------------------------------##

# Clean-up
echo -e "${orange_yellow} Clean-up ${white}"
rm -rf out/*
rm -rf error.log
rm -rf changelog/*
rm -rf ./*.tar.gz

##------------------------------------------------------##

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

# Calculate how long compiling compiling the kernel took
BUILD_START=$(date +"%s")
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))

##------------------------------------------------------##

# This script will ask you if you want to compile with GCC or Clang.
echo -e "${magenta}\n👊 Checking which compiler was chosen ${white}"
echo "1. Clang"
echo "2. GCC"
#read -t 4 -p "Enter your choice [1-2]: " choice || {
#  echo -e "$cyan Timeout of 4 seconds reached. No input received. $white"
#}

if [[ $GCC_VERSION =~ "gcc-eva" ]]; then
  choice=2
else
  choice=1
fi

if [[ $choice == 2 ]]; then
  echo -e "$cyan You have chosen to use GCC. $white"
else
  echo -e "$cyan You have chosen to use Clang. $white"
fi

##------------------------------------------------------##

# Targets | Makefile
DEVICENAMES='OnePlus9 lemonade OnePlus9Pro lemonadep OnePlus9TMO lemonadet OnePlus9VZW lemonadev'
DEVICENAME='op9x'
CODENAME='lahaina'
SUFFIX='qgki'

make O=out ARCH=arm64 "vendor/${CODENAME}-${SUFFIX}_defconfig"

##------------------------------------------------------##

# Info
BUILD_DATE=$(date +"%Y-%m-%d %H:%M")

echo -e "$yellow \n Device: $DEVICENAME $white"
echo -e "$yellow Codename: $CODENAME $white"
echo -e "$yellow OP9 list: $DEVICENAMES $white"
echo -e "$yellow Kernel Name: $ANYK_VERSION $white"
echo -e "$yellow Build Date: $BUILD_DATE \n $white"

##------------------------------------------------------##

# Compile the kernel
if [ $choice -eq 1 ]; then
msg $blink_yellow "|| 🔨 Started Compilation with Clang ||" $white
CLANG_ROOTDIR="$(pwd)/${CLANG_VERSION}"
TOOLCHAIN="clang"

build_kernel() {
Start=$(date +"%s")

if [ "$TOOLCHAIN" == ${TOOLCHAIN} ]; then

make -j$(nproc) ARCH=arm64 SUBARCH=arm64 O=out \
	CC="${CLANG_ROOTDIR}/bin/clang" \
	LD="${CLANG_ROOTDIR}/bin/ld.lld" \
	AR="${CLANG_ROOTDIR}/bin/llvm-ar" \
	AS="${CLANG_ROOTDIR}/bin/llvm-as" \
	NM="${CLANG_ROOTDIR}/bin/llvm-nm" \
	OBJCOPY="${CLANG_ROOTDIR}/bin/llvm-objcopy" \
	OBJDUMP="${CLANG_ROOTDIR}/bin/llvm-objdump" \
	STRIP="${CLANG_ROOTDIR}/bin/llvm-strip" \
	CROSS_COMPILE="${CLANG_ROOTDIR}/bin/aarch64-linux-gnu-" \
    CROSS_COMPILE_ARM32="${CLANG_ROOTDIR}/bin/arm-linux-gnueabi-" \
	CLANG_TRIPLE="${CLANG_ROOTDIR}/bin/aarch64-linux-gnu-" \
    CROSS_COMPILE_COMPAT="${CLANG_ROOTDIR}/bin/arm-linux-gnueabi-" \
	LLVM=1 \
	LLVM_IAS=1 \
	2>&1 | tee error.log
fi

End=$(date +"%s")
Diff=$(($End - $Start))
}
build_kernel

elif [ $choice -eq 2 ]; then
# GCC
msg $blink_yellow "|| 🔨 Started Compilation with GCC ||" $white
GCC_ROOTDIR="$(pwd)/${GCC_VERSION}"
GCC_ARM="$(pwd)/gcc"
TOOLCHAIN="gcc"

build_kernel() {
Start=$(date +"%s")

if [ "$TOOLCHAIN" == ${TOOLCHAIN} ]; then

make -j$(nproc) ARCH=arm64 SUBARCH=arm64 O=out INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH="out/modules" \
	PATH=$GCC_ROOTDIR/bin:$GCC_ARM/bin:/usr/bin:${PATH} \
	CROSS_COMPILE=aarch64-elf- \
	CROSS_COMPILE_ARM32=arm-eabi- \
	AR=aarch64-elf-ar \
	NM=llvm-nm \
	LD=ld.lld \
	OBCOPY=llvm-objcopy \
	OBJDUMP=aarch64-elf-objdump \
	STRIP=aarch64-elf-strip \
    DTC_FLAGS+=-q \
    DTC_EXT=$(which dtc) \
    $(head -1 build.config.common) \
	2>&1 | tee error.log \
	2>&1 | tee out/error.log
fi

# $(head -2 build.config.common | tail -1) \

End=$(date +"%s")
Diff=$(($End - $Start))
}
build_kernel

else
  echo "Invalid choice."
  exit 1
fi

##------------------------------------------------------##

# DTBO
BUILD_DTBO=0

if [ -f $(pwd)/out/arch/arm64/boot/Image ]
	then
        if [ BUILD_DTBO = 1 ]
        then
		git clone --depth=1 https://android.googlesource.com/platform/system/libufdt libufdt
                python3 "libufdt/utils/src/mkdtboimg.py" \
					        create "out/arch/arm64/boot/dtbo.img" --page_size=4096 $(pwd)/out/arch/arm64/boot/dts/qcom/*.dtbo
        fi
fi

##------------------------------------------------------##

# Modules
    echo -e "$yellow \n || Modules || $white"
    AKVDR="AnyKernel3/modules/vendor/lib/modules"
    MOD_NAME="$(make kernelrelease -s)"
    KERNEL_VERSION=$(echo "$MOD_NAME" | cut -c -7)
    chmod +x out

    # Change directory owner to your user (id)
    #chown 1006 out
    #chown 1006 /lib/modules/$MOD_NAME

    #mkdir -p out/lib/modules/$MOD_NAME
    make -j$(nproc) modules_install
    echo -e "Linux Version: $KERNEL_VERSION"
    MOD_PATH="out/modules/lib/modules/$MOD_NAME"

	sed -i 's/\(kernel\/[^: ]*\/\)\([^: ]*\.ko\)/\/vendor\/lib\/modules\/\2/g' "$MOD_PATH"/modules.dep
	sed -i 's/.*\///g' "$MOD_PATH"/modules.order
	cp  $(find "$MOD_PATH" -name '*.ko') "$AKVDR"/
	cp "$MOD_PATH"/modules.{alias,dep,softdep} "$AKVDR"/
	cp "$MOD_PATH"/modules.order "$AKVDR"/modules.load

    #cd out/modules/lib/modules/
    #make kernelrelease -s
    #cd ../../../..
	#sed -i 's/\(kernel\/[^: ]*\/\)\([^: ]*\.ko\)/\/vendor\/lib\/modules\/\2/g' "out/modules/lib/modules/5.4.256-McQuaid"/modules.dep
	#sed -i 's/.*\///g' "out/modules/lib/modules/5.4.256-McQuaid"/modules.order
	#cp  $(find "out/modules/lib/modules/5.4.256-McQuaid" -name '*.ko') "AnyKernel3/modules/vendor/lib/modules"/
	#cp "out/modules/lib/modules/5.4.256-McQuaid"/modules.{alias,dep,softdep} "AnyKernel3/modules/vendor/lib/modules"/
	#cp "out/modules/lib/modules/5.4.256-McQuaid"/modules.order "AnyKernel3/modules/vendor/lib/modules"/modules.load

##------------------------------------------------------##

# Zip up the kernel
zip_kernelimage() {
    rm -rf "$(pwd)"/AnyKernel3/Image
    rm -rf "$(pwd)"/AnyKernel3/*.img
    cp -f "$(pwd)"/out/arch/arm64/boot/Image AnyKernel3
    cp -f "$(pwd)"/out/arch/arm64/boot/dtbo.img AnyKernel3

    #cp -f "$(pwd)"/out/vendor_dlkm.img AnyKernel3
    #cp -rf "$(pwd)"/out/arch/arm64/boot/*.img AnyKernel3
    #find "$(pwd)"/out/arch/arm64/boot/ -name '*.img' -exec cp -f {} AnyKernel3 \;
    #rm -rf "$(pwd)"/AnyKernel3/dtbo.img

    # Searches for all files with the .dtb extension
    dtbs=$(find out/arch/arm64/boot/dts/vendor/oplus/lemonadev -name '*.dtb')
    # Combines the contents of all files into a single file
    cat $dtbs > dtb
    # Save the combined file to the directory
    cp dtb "$(pwd)"/AnyKernel3/dtb

    #find out/arch/arm64/boot/dts/vendor/oplus/lemonadev -name '*.dtb' -exec cat {} ; > "
    rm -rf "$(pwd)"/AnyKernel3/*.zip
    BUILD_TIME=$(date +"%d%m%Y-%H%M")
    cd AnyKernel3 || exit
    zip -r9 "${ANYK_VERSION}"-r"${RELEASE}"-"${DEVICENAME}"-"${BUILD_TIME}".zip ./*
    cd ..
    echo -e "  Success! Ak3 zip built "
}

# DTB BUILD | DTB ZIP
dtb_zip() {
	if [[ ! -d AnyKernel3 ]]; then
		error 'Anykernel not present cannot zip'
	fi
    
    # Searches for all files with the .dtb extension
    dtbs=$(find out/arch/arm64/boot/dts/vendor/oplus/lemonadev -name '*.dtb')
    # Combines the contents of all files into a single file
    cat $dtbs > dtb
    # Save the combined file to the directory
    cp dtb "$(pwd)"/AnyKernel3/dtb

	cd AnyKernel3 || exit
    zip -r9 dtbs-only.zip ./*
	cd ..
    echo -e "  Success! dtbs zip built "
}

##------------------------------------------------------##

# Get MD5SUM and SHASUM of the zipped kernel
Hash() {
    SHA=$(shasum "$(pwd)"/AnyKernel3/"${ANYK_VERSION}"-r"${RELEASE}"-"${DEVICENAME}"-"${BUILD_TIME}".zip | cut -f 1 -d '/')
    MD5=$(md5sum "$(pwd)"/AnyKernel3/"${ANYK_VERSION}"-r"${RELEASE}"-"${DEVICENAME}"-"${BUILD_TIME}".zip | cut -f 1 -d '/')
}

##------------------------------------------------------##

msg $green "|| Zipping into a flashable zip ||" $white
FILE="$(pwd)/out/arch/arm64/boot/Image"
DTBO="$(pwd)/out/arch/arm64/boot/dtbo.img"
#if [ -f "$FILE" ]; then
if [ -f "$FILE" ] && [ -f "$DTBO" ]; then
    zip_kernelimage
    #dtb_zip
    Hash
    echo -e "$green << Build completed in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"
    echo -e "The kernel has successfully been compiled and can be found in $(pwd)/AnyKernel3/${greenish_yellow}${ANYK_VERSION}-r${RELEASE}-${DEVICENAME}-${BUILD_TIME}.zip $white"
    echo -e "$greenish_yellow  MD5 Checksum : $MD5 $white"
    echo -e "$greenish_yellow SHA1 Checksum : $SHA $white"
    rm -rf error.log
    read -r -p "Press enter to continue"
    msg $blink_green "|| Enjoy! ^^ ||" $white

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
    megaput $(pwd)/AnyKernel3/${ANYK_VERSION}-r${RELEASE}-${DEVICENAME}-${BUILD_TIME}.zip -u $email -p $password
    countdown 3
    echo -e "$reset 👍 $white"
    fi

else
    echo -e "$red << Failed to compile the kernel in $(($Diff / 60)) minutes and $(($Diff % 60)) seconds >> \n $white"
    cat error.log | curl -F 'file=@error.log' https://bin.cyberknight777.dev
    echo -e "$blink_red << Check up to find the error >> $white"
    read -r -p "Press enter to continue"
    msg $blink_green "|| Good luck!  ||" $white
fi

##------------------------------------------------------##

# Check gcc log
if [[ $GCC_VERSION =~ "gcc-eva" ]]; then
    echo -e "$cyan \nGCC log: $white"
    cat out/error.log | curl -F 'file=@out/error.log' https://bin.cyberknight777.dev
fi

##------------------------------------------------------##

# Nuke Ak3
echo -e "$yellow \n👉 Do you want to remove the AnyKernel3 directory? [Y/n] $white"
    read -t 5 -p "$(tput setaf 171) Enter your answer: " response || {
    echo -e "$cyan Timeout of 5 seconds reached. No input received. $white"
    }

if [[ $response =~ ^[Yy]$ ]]; then
    rm -rf AnyKernel3
else
    echo -e "$lgreen AnyKernel3 directory was not removed. $white"
fi

##------------------------------------------------------##

# Nuke Toolchain
echo -e "$yellow \n👉 Do you want to remove the Toolchain directory? [Y/n] $white"
    read -t 5 -p "$(tput setaf 171) Enter your answer: " response || {
    echo -e "$cyan Timeout of 5 seconds reached. No input received. $white"
    }

if [[ $response =~ ^[Yy]$ ]]; then
    rm -rf gcc 
    rm -rf gcc-*
    rm -rf clang-*
else
  echo -e "$lgreen Toolchain directory was not removed. $white"
fi

##------------------------------------------------------##
