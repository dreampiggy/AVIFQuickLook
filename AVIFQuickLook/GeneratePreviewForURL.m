#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import "SDImageAVIFCoder.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    // To complete your generator please implement the function GeneratePreviewForURL in GeneratePreviewForURL.c
    @autoreleasepool {
        
        NSString *path = [(__bridge NSURL *)url path];
        NSData *data = [NSData dataWithContentsOfFile:path];
        UIImage *image = [SDImageAVIFCoder.sharedCoder decodedImageWithData:data options:nil];
        CGImageRef cgImgRef = image.CGImage;
        
        if (cgImgRef == NULL) {
            QLPreviewRequestSetURLRepresentation(preview, url, contentTypeUTI, nil);
            return -1;
        }
        
        CGFloat width = CGImageGetWidth(cgImgRef);
        CGFloat height = CGImageGetHeight(cgImgRef);
        
        // Add image dimensions to title
        NSString *newTitle = [NSString stringWithFormat:@"%@ (%d x %d)", [path lastPathComponent], (int)width, (int)height];
        
        NSDictionary *newOpt = @{   (NSString *)kQLPreviewPropertyDisplayNameKey : newTitle,
            (NSString *)kQLPreviewPropertyWidthKey : @(width),
            (NSString *)kQLPreviewPropertyHeightKey : @(height) };
        
        // Draw image
        CGContextRef ctx = QLPreviewRequestCreateContext(preview, CGSizeMake(width, height), YES, (__bridge CFDictionaryRef)newOpt);
        CGContextDrawImage(ctx, CGRectMake(0,0,width,height), cgImgRef);
        QLPreviewRequestFlushContext(preview, ctx);
        
        // Cleanup
        CGContextRelease(ctx);
        
    }
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}
