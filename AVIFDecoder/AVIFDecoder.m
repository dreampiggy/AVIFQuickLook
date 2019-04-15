//
//  AVIFDecoder.m
//  AVIFQuickLook
//
//  Created by lizhuoli on 2019/4/15.
//  Copyright © 2019 dreampiggy. All rights reserved.
//

#import "AVIFDecoder.h"
#import <Accelerate/Accelerate.h>
#import <avif/avif.h>
#import <AppKit/AppKit.h>

// Convert 8/10/12bit AVIF image into RGBA8888
static void ConvertAvifImagePlanarToRGB(avifImage * avif, uint8_t * outPixels) {
    avifBool usesU16 = avifImageUsesU16(avif);
    BOOL hasAlpha = avif->alphaPlane != NULL;
    size_t components = hasAlpha ? 4 : 3;
    if (usesU16) {
        float maxChannel = (float)((1 << avif->depth) - 1);
        for (int j = 0; j < avif->height; ++j) {
            for (int i = 0; i < avif->width; ++i) {
                uint8_t * pixel = &outPixels[components * (i + (j * avif->width))];
                uint16_t r = *((uint16_t *)&avif->rgbPlanes[AVIF_CHAN_R][(i * 2) + (j * avif->rgbRowBytes[AVIF_CHAN_R])]);
                uint16_t g = *((uint16_t *)&avif->rgbPlanes[AVIF_CHAN_G][(i * 2) + (j * avif->rgbRowBytes[AVIF_CHAN_G])]);
                uint16_t b = *((uint16_t *)&avif->rgbPlanes[AVIF_CHAN_B][(i * 2) + (j * avif->rgbRowBytes[AVIF_CHAN_B])]);
                pixel[0] = (uint8_t)roundf((r / maxChannel) * 255.0f);
                pixel[1] = (uint8_t)roundf((g / maxChannel) * 255.0f);
                pixel[2] = (uint8_t)roundf((b / maxChannel) * 255.0f);
                if (avif->alphaPlane) {
                    uint16_t a = *((uint16_t *)&avif->alphaPlane[(i * 2) + (j * avif->alphaRowBytes)]);
                    pixel[3] = (uint8_t)roundf((a / maxChannel) * 255.0f);
                }
            }
        }
    } else {
        for (int j = 0; j < avif->height; ++j) {
            for (int i = 0; i < avif->width; ++i) {
                uint8_t * pixel = &outPixels[components * (i + (j * avif->width))];
                pixel[0] = avif->rgbPlanes[AVIF_CHAN_R][i + (j * avif->rgbRowBytes[AVIF_CHAN_R])];
                pixel[1] = avif->rgbPlanes[AVIF_CHAN_G][i + (j * avif->rgbRowBytes[AVIF_CHAN_G])];
                pixel[2] = avif->rgbPlanes[AVIF_CHAN_B][i + (j * avif->rgbRowBytes[AVIF_CHAN_B])];
                if (avif->alphaPlane) {
                    pixel[3] = avif->alphaPlane[i + (j * avif->alphaRowBytes)];
                }
            }
        }
    }
}

static void FreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

@implementation AVIFDecoder

+ (nullable CGImageRef)createAVIFImageAtPath:(nonnull NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        return nil;
    }
    if (![AVIFDecoder isAVIFFormatForData:data]) {
        return nil;
    }
    
    return [AVIFDecoder createAVIFImageWithData:data];
}

+ (nullable CGImageRef)createAVIFImageWithData:(nonnull NSData *)data CF_RETURNS_RETAINED {
    // Decode it
    avifRawData rawData = {
        .data = (uint8_t *)data.bytes,
        .size = data.length
    };
    avifImage * avif = avifImageCreateEmpty();
    avifResult result = avifImageRead(avif, &rawData);
    if (result != AVIF_RESULT_OK) {
        avifImageDestroy(avif);
        return nil;
    }
    
    int width = avif->width;
    int height = avif->height;
    BOOL hasAlpha = avif->alphaPlane != NULL;
    size_t components = hasAlpha ? 4 : 3;
    size_t bitsPerComponent = 8;
    size_t bitsPerPixel = components * bitsPerComponent;
    size_t rowBytes = width * bitsPerPixel / 8;
    
    uint8_t * dest = calloc(width * components * height, sizeof(uint8_t));
    if (!dest) {
        avifImageDestroy(avif);
        return nil;
    }
    // convert planar to RGB888/RGBA8888
    ConvertAvifImagePlanarToRGB(avif, dest);
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, dest, rowBytes * height, FreeImageData);
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNone;
    CGColorSpaceRef colorSpaceRef = [self colorSpaceGetDeviceRGB];
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, rowBytes, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    // clean up
    CGDataProviderRelease(provider);
    avifImageDestroy(avif);
    
    return imageRef;
}

#pragma mark - Helper
+ (BOOL)isAVIFFormatForData:(nullable NSData *)data
{
    if (!data) {
        return NO;
    }
    if (data.length >= 12) {
        //....ftypavif ....ftypavis
        NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(4, 8)] encoding:NSASCIIStringEncoding];
        if ([testString isEqualToString:@"ftypavif"]
            || [testString isEqualToString:@"ftypavis"]) {
            return YES;
        }
    }
    
    return NO;
}

+ (CGColorSpaceRef)colorSpaceGetDeviceRGB {
    CGColorSpaceRef screenColorSpace = NSScreen.mainScreen.colorSpace.CGColorSpace;
    if (screenColorSpace) {
        return screenColorSpace;
    }
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    });
    return colorSpace;
}

@end
