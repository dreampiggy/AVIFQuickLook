//
//  Conversion.h
//  SDWebImageAVIFCoder
//
//  Created by Ryo Hirafuji on 2020/03/15.
//

#pragma once
#if __has_include(<libavif/avif.h>)
#import <libavif/avif.h>
#else
#import "avif/avif.h"
#endif

extern CGImageRef _Nullable SDCreateCGImageFromAVIF(avifImage * _Nonnull avif) __attribute__((visibility("hidden")));
