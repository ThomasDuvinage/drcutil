######## Please don't edit from here ########
OSNAME="$(uname)"

if [ "$OSNAME" = "Darwin" ]; then
    DIST_KIND=darwin
else
    case $(lsb_release -is) in
	Debian)
            DIST_KIND=debian
            DIST_VER="$(lsb_release -rs | cut -f 1 -d .)"
	    INTERNAL_MACHINE=1
            ;;
	Ubuntu)
            DIST_KIND=ubuntu
            DIST_VER="$(lsb_release -rs)"
            ;;
	*)
            echo 1>&2 "config.sh: error: unknown distribution: $(lsb_release -is)"
            exit 1
            ;;
    esac
fi

case $(uname -m) in
    x86_64 | aarch64)
        ARCH_BITS=64
        ;;
    x86|i[3-6]86)
        ARCH_BITS=32
        ;;
    *)
        echo 1>&2 "config.sh: error: unknown architecture: $(uname -m)"
        exit 1
        ;;
esac

err_report() {
    echo "Error on line $2:$1"
    echo "Stopping the script $(basename "$3")."
}

ENABLE_SAN=0
SAN_CXXFLAGS=()
SAN_CFLAGS=()

case $ENABLE_ASAN in
    1|w)
        ENABLE_SAN=1
        if [ "$ENABLE_ASAN" = w ]; then
            # NB: undocumented flags, may be subject to change or deprecation.
            if "${CXX:-c++}" --version | grep -q 'clang '; then
                ASAN_WRITES_ONLY="-mllvm -asan-instrument-reads=false"
            else
                ASAN_WRITES_ONLY="--param asan-instrument-reads=0"
            fi
        else
            ASAN_WRITES_ONLY=
        fi
        # Reportedly, older gcc and clang require this flag in order
        # to detect some common errors (but still older ones don't
        # recognize the flag).  This page:
        # https://github.com/google/sanitizers/wiki/AddressSanitizer
        # suggests also using several runtime options, but how
        # necessary they are is unclear.
        ASAN_EXTRAS=-fsanitize-address-use-after-scope
        if ! echo | "${CXX:-c++}" -fsanitize=address $ASAN_EXTRAS \
                                  -E -o /dev/null - 2>/dev/null
        then
            ASAN_EXTRAS=
        fi

        SAN_CXXFLAGS+=" -fsanitize=address $ASAN_EXTRAS $ASAN_WRITES_ONLY"
        SAN_CFLAGS+=" -fsanitize=address $ASAN_EXTRAS $ASAN_WRITES_ONLY"
        SAN_LDFLAGS+=" -fsanitize=address"
        # Report, but don't fail on, leaks in program samples during build.
        export LSAN_OPTIONS="exitcode=0"
        ;;
    0)
        ;;
esac

if [ "$ENABLE_TSAN" = 1 ]; then
    ENABLE_SAN=1
    SAN_CXXFLAGS+=" -fsanitize=thread"
    SAN_CFLAGS+=" -fsanitize=thread"
fi

if [ "$ENABLE_SAN" = 1 ]; then
    # For autoconf-based packages, sanitizer flags should NOT be
    # passed into configure because they interfere with detecting the
    # flags needed for pthreads, causing problems later on.  They are
    # instead collected in a dedicated array to be passed into make.
    SAN_FLAGS=(CXXFLAGS="$SAN_CXXFLAGS" CFLAGS="$SAN_CFLAGS")
else
    SAN_FLAGS=()
fi
