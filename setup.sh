#!/bin/bash

# >>>>>> HELPER FUNCTIONS

### Color  Variables ###
red='\e[31m'
green='\e[32m'
yellow='\e[33m'
blue='\e[34m'
purple='\e[35m'
clear='\e[0m'

function echoSection {
    echo -en "$green\n*----------------\n* \n* " $1 "\n* \n*---------------$clear\n"
} 

function echoLine {
  echo -en "$yellow\n-- " $1 "$clear\n"
}

function echoWarn {
    echo -en "$red\n*----------------\n* \n* " $1 "\n* \n*---------------$clear\n"
}

function echoFail {
    echo -en "$red\n*----------------\n* \n* " $1 "\n* \n*---------------$clear\n"
}

function echoConfirm {
    echo -en "\n$purple\n*$clear  $1? [Y/n] "
    read -p  "" -n 1 -r
    echo -en "$clear\n"          
}

ColorGreen(){
    echo -en $green$1$clear
}
ColorBlue(){
    echo -en $blue$1$clear
}
#END HELPER FUNCTIONS <<<<<<<<

UPDATEONCE=0;
HAXEVERSION="423"

function installOpenFLPi {
    
    haxelib install format
    haxelib install hxp
    haxelib install hxcpp
    haxelib install openfl
    haxelib run openfl setup

    echoSection "Go to \n* https://patreon.com/gepatto \n*  and become a patron to get the compiled alpha version of the RPi/lime.ndll \n*  then copy the RPi/lime.ndll to lime/ndll/RPi/lime.ndll"

    echoLine "Don't forget to enable the FKMS-driver in raspi-config->Advanced Options->GL Driver"

}


function installHaxeBinaries {
    
    if [ ! -f "./haxe-binaries$HAXEVERSION.tgz" ]; 
    then
        echoSection "binary archive is missing";
        exit;
    fi

    echoLine "unpacking binaries"
    tar zxf haxe-binaries$HAXEVERSION.tgz

    echoLine "making dir: /usr/local/share/haxe/"
    sudo mkdir -p /usr/local/share/haxe/
    
    cd docker_haxe

    echoLine "copying haxe and haxelib binaries to /usr/local/bin/"
    sudo cp haxe /usr/local/bin/
    sudo cp haxelib /usr/local/bin/

    echoLine "copying haxe std lib to to /usr/local/share/haxe/std"
    sudo cp -R std /usr/local/share/haxe/

    cd ../
    rm -Rf docker_haxe

    echoLine "adding HAXE_STD_PATH to ~/.baschrc"
    if [ `grep 'export HAXE_STD_PATH' ~/.bashrc | wc -l` -eq 0 ]; then
        echo -e "\nexport HAXE_STD_PATH=\"/usr/local/share/haxe/std\"" >> ~/.bashrc
    fi

    NEKO_INSTALLED=$(dpkg-query -W --showformat='${Status}\n' neko|grep "install ok installed")
    if [ "" == "$NEKO_INSTALLED" ]; then
        echoLine "installing neko"
        sudo apt install neko
    else 
        echoLine "neko allready installed"
    fi 
   
    
    echoLine "installing some dependencies so we can compile lime"
    echo

    sudo apt install -y libdrm-dev libgbm-dev libx11-dev libxext-dev libgles2-mesa-dev libasound2-dev libudev-dev
    sudo apt install -y libxcursor-dev libxinerama-dev libxi-dev libxrandr-dev libdbus-1-dev

    if [ ! -d "/home/pi/Development/haxe/lib" ]
    then        
        echoConfirm "Would you like to setup a Development directory for haxe and haxelib?\n--  ~/Development/haxe/dev and ~/Development/haxe/lib"
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            mkdir -p ~/Development/haxe/{dev,lib}
            cd ~/Development/haxe/
            haxelib setup lib
        fi
    fi

    echoLine "All Done: running haxe --version command"

    HAXEVERSION=`haxe --version`

    echoLine "Haxe Version ${HAXEVERSION}" 
}

function menu(){
    echoSection "I want to"
    echo -ne "
$(ColorGreen '1)') Install Haxe from binaries
$(ColorGreen '2)') Install and setup openFL
$(ColorGreen '0)') Exit
$(ColorBlue 'Choose an option:') "
        read a
        case $a in
            1) installHaxeBinaries ; menu ;;
            2) installOpenFLPi ; menu ;;
        0) exit 0 ;;
        *) echo -e $red"Wrong option."$clear; WrongCommand;;
        esac
}

menu