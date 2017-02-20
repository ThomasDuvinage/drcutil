#!/usr/bin/env bash

DRCUTIL=$PWD

source config.sh
FILENAME="$(echo $(cd $(dirname "$BASH_SOURCE") && pwd -P)/$(basename "$BASH_SOURCE"))"
RUNNINGSCRIPT="$0"
trap 'err_report $LINENO $FILENAME $RUNNINGSCRIPT; exit 1' ERR

export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
export PATH=$PREFIX/bin:$PATH

if [ "$ENABLE_ASAN" -eq 1 ]; then
    BUILD_TYPE=RelWithDebInfo
    ASAN_OPTIONS=(-DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-O2 -g -DNDEBUG -fsanitize=address" -DCMAKE_C_FLAGS_RELWITHDEBINFO="-O2 -g -DNDEBUG -fsanitize=address")
else
    ASAN_OPTIONS=()
fi

cmake_install_with_option() {
    SUBDIR="$1"
    shift

    # check existence of the build directory
    if [ ! -d "$SRC_DIR/$SUBDIR/build" ]; then
        mkdir "$SRC_DIR/$SUBDIR/build"
    fi
    cd "$SRC_DIR/$SUBDIR/build"

    COMMON_OPTIONS=(-DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" "${ASAN_OPTIONS[@]}")
    echo cmake $(printf "'%s' " "${COMMON_OPTIONS[@]}" "$@") ..

    cmake "${COMMON_OPTIONS[@]}" "$@" ..

    $SUDO make -j$MAKE_THREADS_NUMBER install
}

cd $SRC_DIR/OpenRTM-aist
if [ ! -e configure ]; then
    ./build/autogen
fi
if [ $BUILD_TYPE != "Release" ]; then
    EXTRA_OPTION=(--enable-debug)
else
    EXTRA_OPTION=()
fi
./configure --prefix="$PREFIX" --without-doxygen "${EXTRA_OPTION[@]}"

if [ "$ENABLE_ASAN" -eq 1 ]; then
    # We set -fsanitize=address here, after configure, because this
    # flag interferes with detecting the flags needed for pthreads,
    # causing problems later on.
    EXTRA_OPTION=(CXXFLAGS="-O2 -g3 -fsanitize=address" CFLAGS="-O2 -g3 -fsanitize=address")
    # Report, but don't fail on, leaks in program samples during build.
    export LSAN_OPTIONS="exitcode=0"
else
    EXTRA_OPTION=()
fi
$SUDO make -j$MAKE_THREADS_NUMBER install "${EXTRA_OPTION[@]}"

cmake_install_with_option "openhrp3" -DCOMPILE_JAVA_STUFF=OFF -DBUILD_GOOGLE_TEST="$BUILD_GOOGLE_TEST" -DOPENRTM_DIR="$PREFIX"

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    if [ "$UBUNTU_VER" != "16.04" ]; then
	cmake_install_with_option "octomap-$OCTOMAP_VERSION"
    fi
    EXTRA_OPTION=()
else
    EXTRA_OPTION=(-DINSTALL_HRPIO=OFF)
fi
cmake_install_with_option hrpsys-base -DCOMPILE_JAVA_STUFF=OFF -DBUILD_KALMAN_FILTER=OFF -DBUILD_STABILIZER=OFF -DENABLE_DOXYGEN=OFF "${EXTRA_OPTION[@]}"
cmake_install_with_option HRP2 -DROBOT_NAME=HRP2KAI
cmake_install_with_option HRP2KAI
cmake_install_with_option HRP5P
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    EXTRA_OPTION=()
else
    EXTRA_OPTION=(-DGENERATE_FILES_FOR_SIMULATION=OFF)
fi
cmake_install_with_option sch-core
cmake_install_with_option hmc2 -DCOMPILE_JAVA_STUFF=OFF "${EXTRA_OPTION[@]}"
cmake_install_with_option hrpsys-humanoid -DCOMPILE_JAVA_STUFF=OFF "${EXTRA_OPTION[@]}"
cmake_install_with_option hrpsys-private
cmake_install_with_option state-observation -DCMAKE_INSTALL_LIBDIR=lib
cmake_install_with_option hrpsys-state-observation
if [ "$INTERNAL_MACHINE" -eq 0 ]; then
    if [ "$IS_VIRTUAL_BOX" -eq 1 ]; then
      CHOREONOID_CMAKE_CXX_FLAGS="-DJOYSTICK_DEVICE_PATH=\"/dev/input/js1\" $CHOREONOID_CMAKE_CXX_FLAGS" #mouse integration uses /dev/input/js1 in virtualbox
    fi
    # FIXME?: This doesn't look right.  CMAKE_CXX_FLAGS is ignored
    # unless CMAKE_BUILD_TYPE is empty, which it is not by default.
    cmake_install_with_option "choreonoid" -DENABLE_CORBA=ON -DBUILD_CORBA_PLUGIN=ON -DBUILD_OPENRTM_PLUGIN=ON -DBUILD_PCL_PLUGIN=ON -DBUILD_OPENHRP_PLUGIN=ON -DBUILD_GRXUI_PLUGIN=ON -DBODY_CUSTOMIZERS="$SRC_DIR/HRP2/customizer/HRP2Customizer;$SRC_DIR/HRP5P/customizer/HRP5PCustomizer" -DBUILD_DRC_USER_INTERFACE_PLUGIN=ON -DCMAKE_CXX_FLAGS="$CHOREONOID_CMAKE_CXX_FLAGS" -DROBOT_HOSTNAME="$ROBOT_HOSTNAME"
    if [ "$BUILD_FRAP_FPE" -eq 1 ]; then
	if [ "$ENABLE_ASAN" -eq 1 ]; then
	    FRAP_FPE_EXTRA_OPTION=(-DTRAP_FPE_SANITIZER_WORKAROUND=ON)
	else
	    FRAP_FPE_EXTRA_OPTION=()
	fi
	cmake_install_with_option trap-fpe "-DTRAP_FPE_BLACKLIST=$DRCUTIL/trap-fpe.blacklist.ubuntu$UBUNTU_VER" "${TRAP_FPE_EXTRA_OPTION[@]}"
    fi

    mkdir -p $HOME/.config/Choreonoid
    cp $DRCUTIL/.config/Choreonoid.conf $DRCUTIL
    sed -i -e "s#/home/vagrant/src#$SRC_DIR#g" $DRCUTIL/Choreonoid.conf
    sed -i -e "s#/home/vagrant/openrtp#$PREFIX#g" $DRCUTIL/Choreonoid.conf
    if [ ! -e $HOME/.config/Choreonoid/Choreonoid.conf ];then
	cp $DRCUTIL/Choreonoid.conf $HOME/.config/Choreonoid
    fi
else
    cmake_install_with_option flexiport -DBUILD_DOCUMENTATION=OFF
    cmake_install_with_option hokuyoaist -DBUILD_DOCUMENTATION=OFF -DBUILD_PYTHON_BINDINGS=OFF
    cmake_install_with_option rtchokuyoaist -DBUILD_DOCUMENTATION=OFF
fi

echo "add the following line to your .bashrc"
echo "source $DRCUTIL/setup.bash"
echo "export PATH=$PREFIX/bin:\$PATH" > $DRCUTIL/setup.bash
echo "export LD_LIBRARY_PATH=$PREFIX/lib:\$LD_LIBRARY_PATH" >> $DRCUTIL/setup.bash
echo "export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig" >> $DRCUTIL/setup.bash
echo "export PYTHONPATH=$PREFIX/lib/python2.7/dist-packages/hrpsys:\$PYTHONPATH" >> $DRCUTIL/setup.bash
