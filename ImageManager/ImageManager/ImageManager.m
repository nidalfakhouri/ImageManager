//
//  ImageManager.m
//  Day07-UnitTesting
//
//  Created by Nidal Fakhouri on 12/16/14.
//  Copyright (c) 2014 mobiquityinc. All rights reserved.
//

#import "ImageManager.h"
#import <AFNetworking/AFNetworking.h>

@interface ImageManager ()

@property (nonatomic, strong) NSMutableSet *activeDownloads;
@property (nonatomic, strong) NSMutableSet *imagesOnDisk;

@end

@implementation ImageManager

#pragma mark - sharedInstance

+ (ImageManager *)sharedInstance
{
    // Declare a static variable to hold the instance of your class, ensuring it’s available globally inside your class.
    static ImageManager *sharedInstance = nil;
    
    // Declare the static variable dispatch_once_t which ensures that the initialization code executes only once.
    static dispatch_once_t oncePredicate;
    
    // Use Grand Central Dispatch (GCD) to execute a block which initializes an instance of LibraryAPI.
    // This is the essence of the Singleton design pattern: the initializer is never called again once the class has been instantiated.
    dispatch_once(&oncePredicate, ^{
        sharedInstance = [[ImageManager alloc] init];
        sharedInstance.activeDownloads = [NSMutableSet set];
        
        // build the cache
        NSArray *imagePaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[ImageManager imagesFilePath] error:nil];
        sharedInstance.imagesOnDisk = [NSMutableSet setWithArray:imagePaths];
    });
    
    return sharedInstance;
}


#pragma mark - notify delegate

- (void)notifyDelegate:(id <ImageManagerDelegate>)delegate withImage:(UIImage *)image forImageInfo:(ImageInfo *)imageInfo
{
    if ([delegate respondsToSelector:@selector(imageManagerDidDownloadImage:withImageInfo:)] == YES) {
        [delegate imageManagerDidDownloadImage:image withImageInfo:imageInfo];
    }
}

- (void)notifyDelegate:(id <ImageManagerDelegate>)delegate withError:(NSError *)error forImageInfo:(ImageInfo *)imageInfo
{
    if ([delegate respondsToSelector: @selector(imageManagerFailedWithError:forImageInfo:)] == YES) {
        [delegate imageManagerFailedWithError:error forImageInfo:imageInfo];
    }
}



#pragma mark - Download

- (void)downloadImageWithImageInfo:(ImageInfo *)imageInfo andDelegate:(id <ImageManagerDelegate>)delegate
{
    //
    [ImageManager createImagesFolderIfNotCreated];
    
    if (imageInfo != nil && imageInfo.remoteURLString != nil) {
        
        // get the image name for the url
        NSString *imageName = [self filePathForImageInfo:imageInfo];
        
        //
        if ([self.imagesOnDisk containsObject:imageName] == YES) {
            UIImage *imageOnDisk = [self imageForImageInfo:imageInfo];
            [self notifyDelegate:delegate withImage:imageOnDisk forImageInfo:imageInfo];
        }
        else if ([self shouldProceedWithDownloadForImageInfo:imageInfo] == YES) {
            
            [self addImageInfoToActiveDownloads:imageInfo];
            
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageInfo.remoteURLString]];
            
            AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
            
            [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                NSData *data = (NSData *)responseObject;
                
                [data writeToFile:[self filePathForImageInfo:imageInfo] atomically:YES];
                
                [self.imagesOnDisk addObject:imageName];
                
                [self removeImageInfoFromActiveDownloads:imageInfo];
                [self notifyDelegate:delegate withImage:[UIImage imageWithData:data] forImageInfo:imageInfo];
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Image error: %@", error);
                [self removeImageInfoFromActiveDownloads:imageInfo];
                [self notifyDelegate:delegate withError:error forImageInfo:imageInfo];
            }];
            
            [requestOperation start];
        }
    }
}


#pragma mark - Download Queue Helpers

- (NSString *)filePathForImageInfo:(ImageInfo *)imageInfo
{
    NSString *filePath = [[ImageManager imagesFilePath] stringByAppendingPathComponent:imageInfo.fileName];
    
    return filePath;
}

- (UIImage *)imageForImageInfo:(ImageInfo *)imageInfo
{
    UIImage *image = [UIImage imageWithContentsOfFile:[self filePathForImageInfo:imageInfo]];
    
    return image;
}

- (BOOL)shouldProceedWithDownloadForImageInfo:(ImageInfo *)imageInfo
{
    return ![self.activeDownloads containsObject:imageInfo.remoteURLString];
}

- (void)addImageInfoToActiveDownloads:(ImageInfo *)imageInfo
{
    [self.activeDownloads addObject:imageInfo.remoteURLString];
}

- (void)removeImageInfoFromActiveDownloads:(ImageInfo *)imageInfo
{
    [self.activeDownloads removeObject:imageInfo.remoteURLString];
}


#pragma mark - File Management

+ (NSString *)imagesFilePath
{
    static NSString *imagesFilePath = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        imagesFilePath = [cachesDirectory stringByAppendingPathComponent:@"Images"];
    });
    
    return imagesFilePath;
}

+ (BOOL)doesImageFolderExsist
{
    static BOOL doesImageFolderExsist = NO;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        doesImageFolderExsist = [[NSFileManager defaultManager] fileExistsAtPath:[ImageManager imagesFilePath]];
        NSLog(@"imagesFilePath: %@", [ImageManager imagesFilePath]);
    });
    
    return doesImageFolderExsist;
}

+ (void)createImagesFolderIfNotCreated
{
    if ([ImageManager doesImageFolderExsist] == NO) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:[ImageManager imagesFilePath]
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
    }
}

- (void)removeAllImages
{
    [[NSFileManager defaultManager] removeItemAtPath:[ImageManager imagesFilePath] error:nil];
    self.imagesOnDisk = [NSMutableSet set];
}

@end


//-----------------------------------------------------------------------------------------------------------------

@implementation ImageInfo

- (instancetype)initWithWithURLString:(NSString *)URLString
{
    self = [super init];
    
    if (self != nil) {
        _remoteURLString = URLString;
    }
    
    return self;
}

- (NSString *)fileName
{
    NSArray *pathComponents = [self.remoteURLString pathComponents];
    
    NSString *imageName = [pathComponents lastObject];
    
    if (self.fileNamePrefix != nil) {
        imageName = [NSString stringWithFormat:@"%@_%@", self.fileNamePrefix, imageName];
    }
    
    return imageName;
}

@end

//-----------------------------------------------------------------------------------------------------------------
