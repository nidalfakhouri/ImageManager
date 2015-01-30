//
//  ImageManagerTests.m
//  ImageManagerTests
//
//  Created by Nidal Fakhouri on 1/29/15.
//  Copyright (c) 2015 nidalfakhouri. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SyncAsyncRunner.h"
#import "ImageManager.h"


//------------------------------------------------------------------------------------------------------------
// unit testing category

@interface ImageManager (UnitTests)

- (NSString *)filePathForImageInfo:(ImageInfo *)imageInfo;
- (UIImage *)imageForImageInfo:(ImageInfo *)imageInfo;

- (BOOL)shouldProceedWithDownloadForImageInfo:(ImageInfo *)imageInfo;
- (void)addImageInfoToActiveDownloads:(ImageInfo *)imageInfo;
- (void)removeImageInfoFromActiveDownloads:(ImageInfo *)imageInfo;

+ (NSString *)imagesFilePath;
+ (BOOL)doesImageFolderExsist;
+ (void)createImagesFolderIfNotCreated;

@end

//------------------------------------------------------------------------------------------------------------


@interface ImageManagerTests : XCTestCase <ImageManagerDelegate>

@property (nonatomic, strong) SyncAsyncRunner *syncAsyncRunner;
@property (nonatomic, strong) UIImage *lastImageDownloaded;

@end

@implementation ImageManagerTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.syncAsyncRunner = [[SyncAsyncRunner alloc] init];
    
    [[ImageManager sharedInstance] removeAllImages];
}

- (void)tearDown
{
    self.syncAsyncRunner = nil;
    
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


#pragma mark - image manager tests

- (void)testAddImageURL
{
    ImageInfo *imageInfo = [self defaultImageInfo];

    [[ImageManager sharedInstance] addImageInfoToActiveDownloads:imageInfo];
    
    XCTAssertFalse([[ImageManager sharedInstance] shouldProceedWithDownloadForImageInfo:imageInfo], @"");
    
    [[ImageManager sharedInstance] removeImageInfoFromActiveDownloads:imageInfo];
    
    XCTAssertTrue([[ImageManager sharedInstance] shouldProceedWithDownloadForImageInfo:imageInfo], @"");
}

- (void)testCreateImagesFolder
{
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[ImageManager imagesFilePath]], @"");
    
    [ImageManager createImagesFolderIfNotCreated];
    
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[ImageManager imagesFilePath]], @"");
}

- (void)testRemoveAllImages
{
    ImageInfo *imageInfo = [self defaultImageInfo];
    
    [[ImageManager sharedInstance] downloadImageWithImageInfo:imageInfo andDelegate:self];
    
    [self.syncAsyncRunner waitForResponse];
    
    XCTAssertNotNil(self.lastImageDownloaded, @"");
    
    [[ImageManager sharedInstance] removeAllImages];
    
    NSString *filePath = [[ImageManager sharedInstance] filePathForImageInfo:imageInfo];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:filePath], @"");
}

- (void)testDownloadImageAndCheckItIsOnDisk
{
    [self downloadImageInfo:[self defaultImageInfo]];
}

- (void)testDownloadImageWithPrefixAndCheckItIsOnDisk
{
    [self downloadImageInfo:[self imageInfoWithPrefix]];
}

- (void)downloadImageInfo:(ImageInfo *)imageInfo
{
    [[ImageManager sharedInstance] downloadImageWithImageInfo:imageInfo andDelegate:self];
    
    [self.syncAsyncRunner waitForResponse];
    
    XCTAssertNotNil(self.lastImageDownloaded, @"");
    
    UIImage *image = [[ImageManager sharedInstance] imageForImageInfo:imageInfo];
    
    XCTAssertNotNil(image, @"");
    
    unsigned char *raster1 = [self returnRasterForImage:image];
    size_t rastster1Size = [self lengthOfBufferForImage:image];
    
    unsigned char *raster2 = [self returnRasterForImage:self.lastImageDownloaded];
    size_t rastster2Size = [self lengthOfBufferForImage:self.lastImageDownloaded];
    
    XCTAssertTrue(rastster1Size == rastster2Size);
    
    if (rastster1Size == rastster2Size) {
        for (int i = 0; i < rastster1Size; i++) {
            XCTAssertTrue(raster1[i] == raster2[i], @"raster1[i]: %@ - v2: %@", @(raster1[i]), @(raster2[i]));
        }
    }
    
    free(raster1);
    free(raster2);
}

#pragma mark - ImageManagerDelegate

- (void)imageManagerDidDownloadImage:(UIImage *)image withImageInfo:(ImageInfo *)imageInfo
{
    self.lastImageDownloaded = image;
    [self.syncAsyncRunner stopWaiting];
}

- (void)imageManagerFailedWithError:(NSError *)error forImageInfo:(ImageInfo *)imageInfo
{
    [self.syncAsyncRunner stopWaiting];
}


#pragma mark - helpers

- (ImageInfo *)defaultImageInfo
{
    ImageInfo *defaultInfo = [[ImageInfo alloc] initWithWithURLString:@"http://www.providencechums.org/images/providence-down.jpg"];
    return defaultInfo;
}

- (ImageInfo *)imageInfoWithPrefix
{
    ImageInfo *imageInfoWithPrefix = [[ImageInfo alloc] initWithWithURLString:@"http://www.providencechums.org/images/providence-down.jpg"];
    imageInfoWithPrefix.fileNamePrefix = @"PREFIX";
    return imageInfoWithPrefix;
}

- (size_t)lengthOfBufferForImage:(UIImage*)inputImage
{
    CGImageRef imageRef = inputImage.CGImage;
    
    size_t imgWidth = CGImageGetWidth(imageRef);
    size_t imgHeight = CGImageGetHeight(imageRef);
    
    size_t NumberOfBytes = imgWidth * imgHeight * 4;
    
    return NumberOfBytes;
}

- (unsigned char *)returnRasterForImage:(UIImage*)inputImage
{
    CGImageRef imageRef = inputImage.CGImage;
    
    //Create a bitmap context to draw the uiimage into
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    uint32_t *imgBitmapData;
    
    size_t imgBitsPerPixel = 32;
    size_t imgBitsPerComponent = 8;
    size_t bytesPerPixel = imgBitsPerPixel / imgBitsPerComponent;
    
    size_t imgWidth = CGImageGetWidth(imageRef);
    size_t imgHeight = CGImageGetHeight(imageRef);
    
    size_t imgBytesPerRow = imgWidth * bytesPerPixel;
    size_t imgBufferLength = imgBytesPerRow * imgHeight;
    
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (!colorSpace) {
        NSLog(@"Error allocating color space RGB\n");
    }
    
    // Allocate memory for image data
    imgBitmapData = (uint32_t *)malloc(imgBufferLength);
    
    if (imgBitmapData) {
        //Create bitmap context
        context = CGBitmapContextCreate(imgBitmapData,
                                        imgWidth,
                                        imgHeight,
                                        imgBitsPerComponent,
                                        imgBytesPerRow,
                                        colorSpace,
                                        1 /*kCGImageAlphaPremultipliedLast*/);//RGBA
    }
    
    if (!context) {
        free(imgBitmapData);
        NSLog(@"Bitmap context not created");
    }
    
    CGRect rect = CGRectMake(0, 0, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    
    //Draw image into the context to get the raw image data
    CGContextDrawImage(context, rect, imageRef);
    
    unsigned char *raster_1D = (unsigned char *)CGBitmapContextGetData(context);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    return raster_1D;
}

@end
