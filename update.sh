#!/usr/bin/env bash
set -euo pipefail
set -x

# `git clone --depth 1` but at a specific revision
git_clone() {
    repo=$1
    dir=$2

    rm -rf "$dir"
    mkdir "$dir"
    pushd "$dir"
    git init -q
    git fetch "$repo" --depth 1
    git checkout -q FETCH_HEAD
    popd
}

# macOS: use gsed for GNU compatibility
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sed=$(which sed)
else
    sed=gsed
fi

# xkbcommon
rm -rf xkbcommon
git_clone https://github.com/xkbcommon/libxkbcommon.git _xkbcommon
mv _xkbcommon/include/xkbcommon .
rm -rf _xkbcommon

# Xlib
rm -rf X11
mkdir -p X11/extensions
git_clone https://gitlab.freedesktop.org/xorg/lib/libx11.git _xlib
mv _xlib/include/X11/*.h X11
mv _xlib/include/X11/extensions/*.h X11/extensions
# generate config header
$sed \
    -e "s/#undef XTHREADS/#define XTHREADS 1/" \
    -e "s/#undef XUSE_MTSAFE_API/#define XUSE_MTSAFE_API 1/" \
    _xlib/include/X11/XlibConf.h.in > X11/XlibConf.h
rm -rf _xlib

# xcursor
mkdir -p X11/Xcursor
# generate header file with version
xcursor_ver=($(
    curl -L "https://gitlab.freedesktop.org/xorg/lib/libxcursor/-/raw/master/configure.ac" |
        $sed -n 's/.*\[\([0-9]\+\)\.\([0-9]\+\)\.\([0-9]\+\)\].*/\1 \2 \3/p'
))
curl -L "https://gitlab.freedesktop.org/xorg/lib/libxcursor/-/raw/master/include/X11/Xcursor/Xcursor.h.in" |
    $sed \
        -e "s/#undef XCURSOR_LIB_MAJOR/#define XCURSOR_LIB_MAJOR ${xcursor_ver[0]}/" \
        -e "s/#undef XCURSOR_LIB_MINOR/#define XCURSOR_LIB_MINOR ${xcursor_ver[1]}/" \
        -e "s/#undef XCURSOR_LIB_REVISION/#define XCURSOR_LIB_REVISION ${xcursor_ver[2]}/" \
        > X11/Xcursor/Xcursor.h

# xrandr, xfixes, xrender, xinerama, xi, xscrnsaver
curl -LZ \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxrandr/-/raw/master/include/X11/extensions/Xrandr.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxfixes/-/raw/master/include/X11/extensions/Xfixes.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxrender/-/raw/master/include/X11/extensions/Xrender.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxinerama/-/raw/master/include/X11/extensions/Xinerama.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxinerama/-/raw/master/include/X11/extensions/panoramiXext.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxi/-/raw/master/include/X11/extensions/XInput.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxi/-/raw/master/include/X11/extensions/XInput2.h" \
    -O "https://gitlab.freedesktop.org/xorg/lib/libxscrnsaver/-/raw/master/include/X11/extensions/scrnsaver.h" \
    --output-dir X11/extensions

# xext
git_clone https://gitlab.freedesktop.org/xorg/lib/libxext.git _xext
mv _xext/include/X11/extensions/*.h X11/extensions
rm -rf _xext

# xorgproto
git_clone https://gitlab.freedesktop.org/xorg/proto/xorgproto.git _xorgproto
{
    cd _xorgproto/include/X11
    find . -name '*.h'
} | while read -r file; do
    source=_xorgproto/include/X11/$file
    target=X11/$file
    mkdir -p "$(dirname "$target")"
    mv "$source" "$target"
done

# generate template Xpoll.h header
$sed \
    's/@USE_FDS_BITS@/__fds_bits/' \
    _xorgproto/include/X11/Xpoll.h.in > X11/Xpoll.h

# GLX headers
rm -rf GL
mkdir GL
{
    cd _xorgproto/include/GL
    find . -name '*.h'
} | while read -r file; do
    source=_xorgproto/include/GL/$file
    target=GL/$file
    mkdir -p "$(dirname "$target")"
    mv "$source" "$target"
done

rm -rf _xorgproto

# xcb (this one's bad!)
rm -rf xcb
mkdir xcb
git_clone https://gitlab.freedesktop.org/xorg/lib/libxcb.git _xcb
git_clone https://gitlab.freedesktop.org/xorg/proto/xcbproto.git _xcbproto
mv _xcb/src/c_client.py _xcbproto
pushd _xcbproto
./autogen.sh
make
make DESTDIR="$PWD/out" install
mkdir c_client_out
pushd c_client_out
export PYTHONPATH="../out/usr/local/lib/python3.10/site-packages"
for file in ../src/*.xml; do
    # The -c, -l and -s parameter are only used for man page
    # generation and aren't relevant for headers.
    python3 ../c_client.py -c _ -l _ -s _ "$file"
done
popd
popd
mv _xcb/src/*.h xcb
mv _xcbproto/c_client_out/*.h xcb
rm -rf _xcb _xcbproto
