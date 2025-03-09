# x11-headers packaged for the Zig build system

This is a Zig package which provides various X11 headers needed to develop and cross-compile e.g. GLFW applications. It includes development headers for:

* xkbcommon
* x11
* xcb
* xcursor
* xrandr
* xfixes
* xrender
* xinerama
* xi
* xscrnsaver
* xext
* xorgproto
* GLX

## Updating

Since this repository takes files from multiple others, we connot perform a diff directly, so the procedure is to clone all of the repos
then copy the headers over to the main folders and finally perform a diff, this way, if any of the files in said folders are different
from those in the repos it will be seen in the diff.

You may simply update the files by running `update.sh` or update and diff by running `validate.sh`,
both scripts output all their contents to the terminal as they run and both always fetch the latest version of the repos.
If you discover that this repo is not up to date please open a pull request or an issue;

Deleted files, and changes to README.md, build.zig, .github CI files and .gitignore are ignored in the diff.
