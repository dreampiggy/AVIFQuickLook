# AVIFQuickLook

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat) [![Build Status](https://travis-ci.org/dreampiggy/AVIFQuickLook.svg?branch=master)](https://travis-ci.org/dreampiggy/AVIFQuickLook) 

This is the **macOS QuickLook** plugin for [AVIF (AV1 Image File Format)](https://aomediacodec.github.io/av1-avif/).

## Generate Finder thumbnails

![](https://raw.githubusercontent.com/dreampiggy/AVIFQuickLook/master/Screenshot/Thumbnails.png)

## QuickLook the image

![](https://raw.githubusercontent.com/dreampiggy/AVIFQuickLook/master/Screenshot/Preview.png)

These images are from [AVIF Specification Test Files](https://github.com/AOMediaCodec/av1-avif/blob/master/testFiles/)

## Requirements

+ macOS 10.10+

## Install

1. Grab the latest `AVIFQuickLook.qlgenerator` from the [Release Page](https://github.com/dreampiggy/AVIFQuickLook/releases/latest), or build using Xcode.
2. Open Finder
3. `Shift + Command + G`, input `~/Library/QuickLook/` and press Enter. For macOS Catalina above, use `/Library/QuickLook/` instead.
4. Drag `AVIFQuickLook.qlgenerator` into this folder. You may need to enter the password

## Uninstall

1. Open Finder
2. `Shift + Command + G`, input `~/Library/QuickLook/` and press Enter. For macOS Catalina above, use `/Library/QuickLook/` instead.
3. Delete `AVIFQuickLook.qlgenerator`

## Author

DreamPiggy, lizhuoli1126@126.com

## License

This project is released under the *MIT license*, see **LICENSE**.

## Thanks

+ [libavif](https://github.com/joedrago/avif)
+ [aom](https://aomedia.googlesource.com/aom/)

