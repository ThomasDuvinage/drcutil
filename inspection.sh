source config.sh
cd $SRC_DIR

cppcheck_exec() {
    for dir_name in $@; do
        cd "$dir_name"
	echo -n "inspecting $dir_name ... "
        cppcheck --enable=all --inconclusive --xml --xml-version=2 --force . 2> $SRC_DIR/${dir_name}.xml 2>&1
        cd ../
    done
}

cppcheck_exec "openhrp3" "hrpsys-base"

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
if [ "$HAVE_ATOM_ACCESS" -eq 1 ]; then
    cppcheck_exec "HRP2"
fi
fi

cppcheck_exec "HRP2DRC" "hmc2" "hrpsys-humanoid"

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
if [ "$HAVE_ATOM_ACCESS" -eq 1 ]; then
    cppcheck_exec "hrpsys-private"
fi
fi

if [ "$INTERNAL_MACHINE" -eq 0 ]; then
cppcheck_exec "choreonoid"
fi
