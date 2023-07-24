#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import "SDImageAVIFCoder.h"

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    // To complete your generator please implement the function GenerateThumbnailForURL in GenerateThumbnailForURL.c
    @autoreleasepool {
        
        NSString *path = [(__bridge NSURL *)url path];
        NSData *data = [NSData dataWithContentsOfFile:path];
        UIImage *image = [SDImageAVIFCoder.sharedCoder decodedImageWithData:data options:nil];
        CGImageRef cgImgRef = image.CGImage;
        if (cgImgRef) {
            QLThumbnailRequestSetImage(thumbnail, cgImgRef, nil);
        } else {
            QLThumbnailRequestSetImageAtURL(thumbnail, url, nil);
        }
        
    }
    return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
