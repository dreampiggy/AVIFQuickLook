//
//  AVIFDecoder.m
//  AVIFQuickLook
//
//  Created by lizhuoli on 2019/4/15.
//  Copyright © 2019 dreampiggy. All rights reserved.
//

#import "AVIFDecoder.h"
#import "ColorSpace.h"
#import "Conversion.h"
#import <Accelerate/Accelerate.h>
#import <avif/avif.h>
#import <AppKit/AppKit.h>

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
    if (!data) {
        return nil;
    }
    
    // Decode it
    avifDecoder * decoder = avifDecoderCreate();
    avifDecoderSetIOMemory(decoder, data.bytes, data.length);
    // Disable strict mode to keep some AVIF image compatible
    decoder->strictFlags = AVIF_STRICT_DISABLED;
    avifResult decodeResult = avifDecoderParse(decoder);
    if (decodeResult != AVIF_RESULT_OK) {
        NSLog(@"Failed to decode image: %s", avifResultToString(decodeResult));
        avifDecoderDestroy(decoder);
        return nil;
    }
    
    // Static image
//    if (decoder->imageCount <= 1) {
    avifResult nextImageResult = avifDecoderNextImage(decoder);
    if (nextImageResult != AVIF_RESULT_OK) {
        NSLog(@"Failed to decode image: %s", avifResultToString(nextImageResult));
        avifDecoderDestroy(decoder);
        return nil;
    }
    CGImageRef imageRef = SDCreateCGImageFromAVIF(decoder->image);
    avifDecoderDestroy(decoder);
    return imageRef;
//    }
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
