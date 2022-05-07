//
//  ColorSpace.m
//  SDWebImageAVIFCoder
//
//  Created by Ryo Hirafuji on 2020/03/15.
//

#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#if __has_include(<libavif/avif.h>)
#import <libavif/avif.h>
#import <libavif/internal.h>
#else
#import "avif/avif.h"
#import "avif/internal.h"
#endif

static void CalcWhitePoint(uint16_t const colorPrimaries, vImageWhitePoint* const white) {
    float primaries[8];
    avifColorPrimariesGetValues(colorPrimaries, primaries);
    white->white_x = primaries[6];
    white->white_y = primaries[7];
}

static void CalcRGBPrimaries(uint16_t const colorPrimaries, vImageRGBPrimaries* const prim) {
    float primaries[8];
    avifColorPrimariesGetValues(colorPrimaries, primaries);
    prim->red_x = primaries[0];
    prim->red_y = primaries[1];
    prim->green_x = primaries[2];
    prim->green_y = primaries[3];
    prim->blue_x = primaries[4];
    prim->blue_y = primaries[5];
    prim->white_x = primaries[6];
    prim->white_y = primaries[7];
}

static void CalcTransferFunction(uint16_t const transferCharacteristics, vImageTransferFunction* const tf) {
    // See: https://www.itu.int/rec/T-REC-H.273/en
    static const float alpha = 1.099296826809442f;
    static const float beta = 0.018053968510807f;
    /*
     // R' = c0 * pow( c1 * R + c2, gamma ) + c3,    (R >= cutoff)
     // R' = c4 * R + c5                             (R < cutoff)
    */

    switch(transferCharacteristics) {
        case AVIF_TRANSFER_CHARACTERISTICS_BT470BG: // 5, gamma=2.8
            tf->cutoff = -INFINITY;
            tf->c0 = 1.0f;
            tf->c1 = 1.0f;
            tf->c2 = 0.0f;
            tf->c3 = 0.0f;
            tf->c4 = 0.0f;
            tf->c5 = 0.0f;
            tf->gamma = 1.0f/2.8f;
            break;
        case AVIF_TRANSFER_CHARACTERISTICS_BT709: // 1, sRGB
        case AVIF_TRANSFER_CHARACTERISTICS_BT601: // 6
        case AVIF_TRANSFER_CHARACTERISTICS_BT2020_10BIT: // 14
        case AVIF_TRANSFER_CHARACTERISTICS_BT2020_12BIT: // 15
            tf->cutoff = beta;
            //
            tf->c0 = alpha;
            tf->c1 = 1.0f;
            tf->c2 = 0.0f;
            tf->gamma = 0.45f;
            tf->c3 = -(alpha - 1);
            //
            tf->c4 = 4.5f;
            tf->c5 = 0.0f;
            break;
        case AVIF_TRANSFER_CHARACTERISTICS_SMPTE240: // 7
            tf->cutoff = beta;
            //
            tf->c0 = alpha;
            tf->c1 = 1.0f;
            tf->c2 = 0.0f;
            tf->gamma = 0.45f;
            tf->c3 = -(alpha - 1);
            //
            tf->c4 = 4.0f;
            tf->c5 = 0.0f;
            break;
        case AVIF_TRANSFER_CHARACTERISTICS_LINEAR: // 8
            tf->cutoff = INFINITY;
            //
            tf->c0 = 1.0f;
            tf->c1 = 1.0f;
            tf->c2 = 0.0f;
            tf->gamma = 1.0f;
            tf->c3 = 0.0f;
            //
            tf->c4 = 4.0f;
            tf->c5 = 0.0f;
            break;
        case AVIF_TRANSFER_CHARACTERISTICS_IEC61966: // 11
            tf->cutoff = beta;
            //
            tf->c0 = alpha;
            tf->c1 = 1.0f;
            tf->c2 = 0.0f;
            tf->gamma = 0.45f;
            tf->c3 = -(alpha - 1);
            //
            tf->c4 = 4.5f;
            tf->c5 = 0.0f;
            break;
        case AVIF_TRANSFER_CHARACTERISTICS_BT1361: // 12
            tf->cutoff = beta;
            //
            tf->c0 = alpha;
            tf->c1 = 1.0f;
            tf->c2 = 0.0f;
            tf->gamma = 0.45f;
            tf->c3 = -(alpha - 1);
            //
            tf->c4 = 4.5f;
            tf->c5 = 0.0f;
            break;
        case AVIF_TRANSFER_CHARACTERISTICS_SRGB: // 13
            tf->cutoff = beta;
            //
            tf->c0 = alpha;
            tf->c1 = 1.0f;
            tf->c2 = 0.0f;
            tf->gamma = 1.0f/2.4f;
            tf->c3 = -(alpha - 1);
            //
            tf->c4 = 12.92f;
            tf->c5 = 0.0f;
            break;
        case AVIF_TRANSFER_CHARACTERISTICS_SMPTE428: // 17
            tf->cutoff = -INFINITY;
            //
            tf->c0 = 1.0f;
            tf->c1 = 48.0f / 52.37f;
            tf->c2 = 0.0f;
            tf->gamma = 1.0f/2.6f;
            tf->c3 = 0.0f;
            //
            tf->c4 = 1.0f;
            tf->c5 = 0.0f;
            break;
        // Can't be represented by vImageTransferFunction. Use gamma 2.2 as a fallback.
        case AVIF_TRANSFER_CHARACTERISTICS_SMPTE2084: // 16
        case AVIF_TRANSFER_CHARACTERISTICS_HLG: // 18
        case AVIF_TRANSFER_CHARACTERISTICS_LOG100: // 9
        case AVIF_TRANSFER_CHARACTERISTICS_LOG100_SQRT10: // 10
        //
        case AVIF_TRANSFER_CHARACTERISTICS_UNKNOWN: // 0
        case AVIF_TRANSFER_CHARACTERISTICS_UNSPECIFIED: // 2
        case AVIF_TRANSFER_CHARACTERISTICS_BT470M: // 4
        default:
            tf->cutoff = -INFINITY;
            tf->c0 = 1.0f;
            tf->c1 = 1.0f;
            tf->c2 = 0.0f;
            tf->c3 = 0.0f;
            tf->c4 = 0.0f;
            tf->c5 = 0.0f;
            tf->gamma = 1.0f/2.2f;
            break;
    }
}
CGColorSpaceRef SDAVIFCreateColorSpaceMono(avifColorPrimaries const colorPrimaries, avifTransferCharacteristics const transferCharacteristics) {
    if (@available(macOS 10.10, iOS 8.0, tvOS 8.0, *)) {
        vImage_Error err;
        vImageWhitePoint white;
        vImageTransferFunction transfer;
        CalcWhitePoint(colorPrimaries, &white);
        CalcTransferFunction(transferCharacteristics, &transfer);
        CGColorSpaceRef colorSpace = vImageCreateMonochromeColorSpaceWithWhitePointAndTransferFunction(&white, &transfer, kCGRenderingIntentDefault, kvImagePrintDiagnosticsToConsole, &err);
        if(err != kvImageNoError) {
            NSLog(@"[BUG] Failed to create monochrome color space: %ld", err);
            if(colorSpace != NULL) {
                CGColorSpaceRelease(colorSpace);
            }
            return NULL;
        }
        return colorSpace;
    }else{
        return NULL;
    }
}

CGColorSpaceRef SDAVIFCreateColorSpaceRGB(avifColorPrimaries const colorPrimaries, avifTransferCharacteristics const transferCharacteristics) {
    if (@available(macOS 10.10, iOS 8.0, tvOS 8.0, *)) {
        vImage_Error err;
        vImageRGBPrimaries primaries;
        vImageTransferFunction transfer;
        CalcRGBPrimaries(colorPrimaries, &primaries);
        CalcTransferFunction(transferCharacteristics, &transfer);
        CGColorSpaceRef colorSpace = vImageCreateRGBColorSpaceWithPrimariesAndTransferFunction(&primaries, &transfer, kCGRenderingIntentDefault, kvImagePrintDiagnosticsToConsole, &err);
        if(err != kvImageNoError) {
            NSLog(@"[BUG] Failed to create monochrome color space: %ld", err);
            if(colorSpace != NULL) {
                CGColorSpaceRelease(colorSpace);
            }
            return NULL;
        }
        return colorSpace;
    }else{
        return NULL;
    }
}

void SDAVIFCalcColorSpaceMono(avifImage * avif, CGColorSpaceRef* ref, BOOL* shouldRelease) {
    static CGColorSpaceRef defaultColorSpace;
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            defaultColorSpace = CGColorSpaceCreateDeviceGray();
        });
    }
    if(avif->icc.data && avif->icc.size) {
        if(@available(macOS 10.12, iOS 10.0, tvOS 10.0, *)) {
            CFDataRef iccData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, avif->icc.data, avif->icc.size,kCFAllocatorNull);
            *ref = CGColorSpaceCreateWithICCData(iccData);
            CFRelease(iccData);
            *shouldRelease = TRUE;
        }else{
            NSData* iccData = [NSData dataWithBytes:avif->icc.data length:avif->icc.size];
            *ref = CGColorSpaceCreateWithICCProfile((__bridge CFDataRef)iccData);
            *shouldRelease = TRUE;
        }
        return;
    }
    avifColorPrimaries const colorPrimaries = avif->colorPrimaries;
    avifTransferCharacteristics const transferCharacteristics = avif->transferCharacteristics;
    if((colorPrimaries == AVIF_COLOR_PRIMARIES_UNKNOWN ||
        colorPrimaries == AVIF_COLOR_PRIMARIES_UNSPECIFIED) &&
       (transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_UNKNOWN ||
        transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_UNSPECIFIED)) {
        *ref = defaultColorSpace;
        *shouldRelease = FALSE;
        return;
    }
    if(colorPrimaries == AVIF_COLOR_PRIMARIES_BT709 &&
       transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_SRGB) {
        static CGColorSpaceRef sRGB = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sRGB = SDAVIFCreateColorSpaceMono(colorPrimaries, transferCharacteristics);
            if(sRGB == NULL) {
                sRGB = defaultColorSpace;
            }
        });
        *ref = sRGB;
        *shouldRelease = FALSE;
        return;
    }
    if(colorPrimaries == AVIF_COLOR_PRIMARIES_BT709 &&
       transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_BT709) {
        static CGColorSpaceRef bt709 = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            bt709 = SDAVIFCreateColorSpaceMono(colorPrimaries, transferCharacteristics);
            if(bt709 == NULL) {
                bt709 = defaultColorSpace;
            }
        });
        *ref = bt709;
        *shouldRelease = FALSE;
        return;
    }
    if(colorPrimaries == AVIF_COLOR_PRIMARIES_BT2020 &&
       (transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_BT2020_10BIT ||
        transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_BT2020_12BIT)) {
        static CGColorSpaceRef bt2020 = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            bt2020 = SDAVIFCreateColorSpaceMono(colorPrimaries, transferCharacteristics);
            if(bt2020 == NULL) {
                bt2020 = defaultColorSpace;
            }
        });
        *ref = bt2020;
        *shouldRelease = FALSE;
        return;
    }
    if(colorPrimaries == AVIF_COLOR_PRIMARIES_SMPTE432 /* Display P3 */ &&
       transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_SRGB) {
        static CGColorSpaceRef p3 = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            p3 = SDAVIFCreateColorSpaceMono(colorPrimaries, transferCharacteristics);
            if(p3 == NULL) {
                p3 = defaultColorSpace;
            }
        });
        *ref = p3;
        *shouldRelease = FALSE;
        return;
    }

    *ref = SDAVIFCreateColorSpaceMono(colorPrimaries, transferCharacteristics);
    if(*ref != NULL) {
        *shouldRelease = TRUE;
    } else {
        *ref = defaultColorSpace;
        *shouldRelease = FALSE;
    }
}

void SDAVIFCalcColorSpaceRGB(avifImage * avif, CGColorSpaceRef* ref, BOOL* shouldRelease) {
    static CGColorSpaceRef defaultColorSpace = NULL;
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            defaultColorSpace = CGColorSpaceCreateDeviceRGB();
        });
    }
    if(avif->icc.data && avif->icc.size) {
        if(@available(macOS 10.12, iOS 10.0, tvOS 10.0, *)) {
            CFDataRef iccData = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, avif->icc.data, avif->icc.size,kCFAllocatorNull);
            *ref = CGColorSpaceCreateWithICCData(iccData);
            CFRelease(iccData);
            *shouldRelease = TRUE;
        }else{
            NSData* iccData = [NSData dataWithBytes:avif->icc.data length:avif->icc.size];
            *ref = CGColorSpaceCreateWithICCProfile((__bridge CFDataRef)iccData);
            *shouldRelease = TRUE;
        }
        return;
    }
    avifColorPrimaries const colorPrimaries = avif->colorPrimaries;
    avifTransferCharacteristics const transferCharacteristics = avif->transferCharacteristics;
    if((colorPrimaries == AVIF_COLOR_PRIMARIES_UNKNOWN ||
        colorPrimaries == AVIF_COLOR_PRIMARIES_UNSPECIFIED) &&
       (transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_UNKNOWN ||
        transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_UNSPECIFIED)) {
        *ref = defaultColorSpace;
        *shouldRelease = FALSE;
        return;
    }
    if(colorPrimaries == AVIF_COLOR_PRIMARIES_BT709 &&
       transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_BT709) {
        static CGColorSpaceRef bt709 = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (@available(macOS 10.11, iOS 9.0, tvOS 9.0, *)) {
                bt709 = CGColorSpaceCreateWithName(kCGColorSpaceITUR_709);
            } else {
                bt709 = defaultColorSpace;
            }
        });
        *ref = bt709;
        *shouldRelease = FALSE;
        return;
    }
    if(colorPrimaries == AVIF_COLOR_PRIMARIES_BT709 /* sRGB */ &&
       transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_SRGB) {
        static CGColorSpaceRef sRGB = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (@available(macOS 10.5, iOS 9.0, tvOS 9.0, *)) {
                sRGB = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
            } else {
                sRGB = defaultColorSpace;
            }
        });
        *ref = sRGB;
        *shouldRelease = FALSE;
        return;
    }
    if(colorPrimaries == AVIF_COLOR_PRIMARIES_BT709 /* sRGB */ &&
       transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_LINEAR) {
        static CGColorSpaceRef sRGBlinear = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (@available(macOS 10.12, iOS 10.0, tvOS 10.0, *)) {
                sRGBlinear = CGColorSpaceCreateWithName(kCGColorSpaceLinearSRGB);
            } else {
                sRGBlinear = defaultColorSpace;
            }
        });
        *ref = sRGBlinear;
        *shouldRelease = FALSE;
        return;
    }
    if(colorPrimaries == AVIF_COLOR_PRIMARIES_BT2020 &&
       (transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_BT2020_10BIT ||
        transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_BT2020_12BIT)) {
        static CGColorSpaceRef bt2020 = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (@available(macOS 10.11, iOS 9.0, tvOS 9.0, *)) {
                bt2020 = CGColorSpaceCreateWithName(kCGColorSpaceITUR_2020);
            } else {
                bt2020 = defaultColorSpace;
            }
        });
        *ref = bt2020;
        *shouldRelease = FALSE;
        return;
    }
    if(colorPrimaries == AVIF_COLOR_PRIMARIES_BT2020 &&
       transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_LINEAR) {
        static CGColorSpaceRef bt2020linear = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (@available(macOS 10.14.3, iOS 12.3, tvOS 12.3, *)) {
                bt2020linear = CGColorSpaceCreateWithName(kCGColorSpaceExtendedLinearITUR_2020);
            } else {
                bt2020linear = defaultColorSpace;
            }
        });
        *ref = bt2020linear;
        *shouldRelease = FALSE;
        return;
    }
    if(colorPrimaries == AVIF_COLOR_PRIMARIES_SMPTE432 /* Display P3 */ &&
       transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_SRGB) {
        static CGColorSpaceRef p3 = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (@available(macOS 10.11.2, iOS 9.3, tvOS 9.3, *)) {
                p3 = CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
            } else {
                p3 = defaultColorSpace;
            }
        });
        *ref = p3;
        *shouldRelease = FALSE;
        return;
    }
    if(colorPrimaries == AVIF_COLOR_PRIMARIES_SMPTE432 /* Display P3 */ &&
       transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_HLG) {
        static CGColorSpaceRef p3hlg = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (@available(macOS 10.14.6, iOS 13.0, tvOS 13.0, *)) {
                p3hlg = CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3_HLG);
            } else {
                p3hlg = defaultColorSpace;
            }
        });

        *ref = p3hlg;
        *shouldRelease = FALSE;
        return;
    }
    if(colorPrimaries == AVIF_COLOR_PRIMARIES_SMPTE432 /* Display P3 */ &&
       transferCharacteristics == AVIF_TRANSFER_CHARACTERISTICS_LINEAR) {
        static CGColorSpaceRef p3linear = NULL;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            if (@available(macOS 10.14.3, iOS 12.3, tvOS 12.3, *)) {
                p3linear = CGColorSpaceCreateWithName(kCGColorSpaceExtendedLinearDisplayP3);
            } else {
                p3linear = defaultColorSpace;
            }
        });
        *ref = p3linear;
        *shouldRelease = FALSE;
        return;
    }

    *ref = SDAVIFCreateColorSpaceRGB(colorPrimaries, transferCharacteristics);
    if(*ref != NULL) {
        *shouldRelease = TRUE;
    } else {
        *ref = defaultColorSpace;
        *shouldRelease = FALSE;
    }
}
