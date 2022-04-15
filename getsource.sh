#!/usr/bin/env bash

source config.sh

if [ $GITHUB_SSH != "1" ]; then
    GITHUB_LINK=https://github.com/
else
    GITHUB_LINK=git@github.com:
fi

if [ $OSNAME != "Darwin" ]; then
    sudo apt-get -y install git subversion
fi

get_source() {
    if [ ! -e $2 ]; then
	$1 $2
    else
        repo=`echo $1 | rev | cut -d' ' -f1 | rev`
        cd $2
        origin=`git remote get-url origin`
        if [ $repo != $origin ]; then
            echo "set url for origin: $repo"
            git remote set-url origin $repo
        fi
        cd ..
    fi
}

if [ ! -e $SRC_DIR ]; then
  mkdir -p $SRC_DIR 
fi

cd $SRC_DIR

get_source_OpenRTM-aist() {
    #get_source "svn co https://svn.openrtm.org/OpenRTM-aist/branches/RELENG_1_1/OpenRTM-aist" OpenRTM-aist
    get_source "git clone ${GITHUB_LINK}isri-aist/openrtm-aist-cpp.git" OpenRTM-aist
}

get_source_pcl() {
    :
}

get_source_openhrp3() {
    get_source "git clone ${GITHUB_LINK}fkanehiro/openhrp3.git" openhrp3
}

get_source_HRP2() {
    get_source "git clone ${GITHUB_LINK}isri-aist/hrp2" HRP2
}

get_source_HRP2KAI() {
    get_source "git clone ${GITHUB_LINK}isri-aist/hrp2kai" HRP2KAI
}

get_source_HRP5P() {
    get_source "git clone ${GITHUB_LINK}isri-aist/hrp5p" HRP5P
}

get_source_HRP4CR() {
    get_source "git clone --recursive ${GITHUB_LINK}isri-aist/hrp4cr" HRP4CR
}

get_source_hrpsys-private() {
    get_source "git clone ${GITHUB_LINK}isri-aist/hrpsys-private" hrpsys-private
}

get_source_hrpsys-state-observation() {
    get_source "git clone --recursive ${GITHUB_LINK}isri-aist/hrpsys-state-observation" hrpsys-state-observation
}

get_source_hrpsys-base() {
    get_source "git clone ${GITHUB_LINK}fkanehiro/hrpsys-base" hrpsys-base
}

get_source_state-observation() {
    get_source "git clone --recursive ${GITHUB_LINK}jrl-umi3218/state-observation" state-observation
}

get_source_hmc2() {
    get_source "git clone ${GITHUB_LINK}isri-aist/hmc2" hmc2
}

get_source_hrpsys-humanoid() {
    get_source "git clone ${GITHUB_LINK}isri-aist/hrpsys-humanoid" hrpsys-humanoid
}

get_source_sch-core() {
    get_source "git clone --recursive ${GITHUB_LINK}jrl-umi3218/sch-core" sch-core
}

get_source_savedbg() {
    get_source "git clone ${GITHUB_LINK}isri-aist/savedbg" savedbg
    cd savedbg
    git checkout db25d9c9be98f0bce6348bdd425305c799980473
    cd ..
}

get_source_octomap() {
    if ([ "$DIST_KIND" == "ubuntu" ] && [ "$DIST_VER" == "14.04" ]) || ([ "$DIST_KIND" == "debian" ] && [ "$DIST_VER" != "10" ]); then
	if [ ! -e octomap-$OCTOMAP_VERSION ]; then
	    wget https://github.com/OctoMap/octomap/archive/v$OCTOMAP_VERSION.tar.gz
	    tar zxvf v$OCTOMAP_VERSION.tar.gz
	fi
    fi
}

get_source_choreonoid() {
    get_source "git clone ${GITHUB_LINK}isri-aist/choreonoid.git" choreonoid
    cd choreonoid/ext
    if [ "$USE_HRPCNOID" -eq 1 ]; then
	get_source "git clone ${GITHUB_LINK}isri-aist/hrpcnoid" hrpcnoid
    fi
    get_source "git clone ${GITHUB_LINK}isri-aist/cnoid-boost-python" cnoid-boost-python
    get_source "git clone ${GITHUB_LINK}isri-aist/grxui-plugin" grxui-plugin
    get_source "git clone ${GITHUB_LINK}isri-aist/openhrp-plugin" openhrp-plugin
    cd ../..
}

get_source_trap-fpe() {
    if [ ! -e DynamoRIO-$DYNAMORIO_VERSION.tar.gz ]; then
	wget ${GITHUB_LINK}DynamoRIO/dynamorio/releases/download/$DYNAMORIO_RELEASE/DynamoRIO-$DYNAMORIO_VERSION.tar.gz
    fi
    get_source "git clone https://bitbucket.org/jun0-aist/trap-fpe" trap-fpe
}

get_source_flexiport() {
    get_source "git clone ${GITHUB_LINK}gbiggs/flexiport" flexiport
}

get_source_hokuyoaist() {
    get_source "git clone ${GITHUB_LINK}fkanehiro/hokuyoaist" hokuyoaist
}

get_source_rtchokuyoaist() {
    get_source "git clone ${GITHUB_LINK}fkanehiro/rtchokuyoaist" rtchokuyoaist
}

get_source_is-jaxa() {
    get_source "git clone ${GITHUB_LINK}isri-aist/is-jaxa" is-jaxa
}

get_source_takenaka() {
    cd choreonoid/ext
    get_source "git clone ${GITHUB_LINK}isri-aist/takenaka" takenaka
    cd ../..
}

if [ ! $# -eq 0 ]; then
    PACKAGES=$@
fi

for package in $PACKAGES; do
    get_source_$package
done
