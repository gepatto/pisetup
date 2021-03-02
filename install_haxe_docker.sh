#!/bin/bash
# >>>>>> HELPER FUNCTIONS
function echoSection {
    echo -en "\e[33m\n--------------------------------------------------------------------------------\n--\n-- " $1 "\n--\n----------------------------------------------------------------------------------\e[37m\n"          
} 
function echoLine {
  echo -en "\e[33m\n-- " $1 "\e[37m"
}
function echoWarn {
    echo -en "\e[38m\n--------------------------------------------------------------------------------\n--\n-- " $1 "\n--\n--------------------------------------------------------------------------------\e[37m\n"
}
function echoFail {
    echo -en "\e[31m\n--------------------------------------------------------------------------------\n--\n-- " $1 "\n--\n--------------------------------------------------------------------------------\e[37m\n"
}
function echoConfirm {
    echo -en "\n\e[35m------------------------------------------------------------------------------------\n--\n"
    echo -en "--  $1?\n"
    read -p "[Y/n] " -n 1 -r
    echo -en "\n--\n-----------------------------------------------------------------------------------\e[37m\n"          
}
#END HELPER FUNCTIONS <<<<<<<<


#echo $0
DOCKER='/usr/bin/docker'

if [ "$#" -ne 1 ]; then
    echo -en "\nUsage: $0 TAGNAME \ni.e. : \e[3m $0 4.1.5-buster\n\e[0m"
    exit 0;
fi


if test -f "$DOCKER" 
then
    echoLine "Ok you have docker installed, let's get going";
else
    echoConfirm "hmmm Docker is not installed yet, would you like to install (needs reboot)"
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        curl -sSL https://get.docker.com | sh
        sudo usermod -aG docker pi
        echoSection "Docker is now installed, but you need to reboot and run this script again."
        exit 0;
    else
        echoWarn "Ok, not running this script any further"
        exit 0;
    fi
fi

mkdir -p ./docker_haxe/
sudo mkdir -p /usr/local/share/haxe/

echoSection "running/getting docker image";
docker run haxe:$1

echoSection "getting CONTAINERID"

CONTAINERID=`docker ps -aq --latest`

echoLine "copying from container: $CniceONTAINERID"

docker cp $CONTAINERID:/usr/local/bin/haxe ./docker_haxe/
docker cp $CONTAINERID:/usr/local/bin/haxelib ./docker_haxe/
docker cp $CONTAINERID:/usr/local/share/haxe/std  ./docker_haxe/

echoLine "creative haxe-binaries.tgz archive for future use"
tar zcf haxe-binaries.tgz ./docker_haxe

cd ./docker_haxe/
echoSection "copying haxe and haxelib binaries to /usr/local/bin/"
sudo cp haxe /usr/local/bin/
sudo cp haxelib /usr/local/bin/

echoSection "copying haxe std lib to to /usr/local/share/haxe/std"
sudo cp -R std /usr/local/share/haxe/

echoSection "adding HAXE_STD_PATH to ~/.baschrc"
if [ `grep 'export HAXE_STD_PATH' ~/.bashrc | wc -l` -eq 0 ]; then
   echo -e "\nexport HAXE_STD_PATH=\"/usr/local/share/haxe/std\"" >> ~/.bashrc
fi

echoSection "installing neko"
sudo apt install neko

echoSection "installing some dependencies so we can compile lime"
sudo apt-get install libdrm-dev libgbm-dev libx11-dev libxext-dev libgles2-mesa-dev libasound2-dev libudev-dev

echoConfirm "Would you like to setup a Development directory for haxe and haxelib?\n--  ~/Development/haxe/dev and ~/Development/haxe/lib"
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      mkdir -p ~/Development/haxe/{dev,lib}
    fi


echoSection "All Done"
haxe -v