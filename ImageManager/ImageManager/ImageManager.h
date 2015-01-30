//
//  ImageManager.h
//  Day07-UnitTesting
//
//  Created by Nidal Fakhouri on 12/16/14.
//  Copyright (c) 2014 mobiquityinc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ImageInfo;

//-----------------------------------------------------------------------------------------------------------------

@protocol ImageManagerDelegate <NSObject>

- (void)imageManagerDidDownloadImage:(UIImage *)image withImageInfo:(ImageInfo *)imageInfo;
- (void)imageManagerFailedWithError:(NSError *)error forImageInfo:(ImageInfo *)imageInfo;

@end

//-----------------------------------------------------------------------------------------------------------------

@interface ImageManager : NSObject

+ (ImageManager *)sharedInstance;

- (void)downloadImageWithImageInfo:(ImageInfo *)imageInfo andDelegate:(id <ImageManagerDelegate>)delegate;
- (void)removeAllImages;

@end

//-----------------------------------------------------------------------------------------------------------------


@interface ImageInfo : NSObject

- (instancetype)initWithWithURLString:(NSString *)URLString;

@property (nonatomic, copy) NSString *remoteURLString;
@property (nonatomic, copy) NSString *fileNamePrefix;

/*
 if the prefix is nil, this will just return the last path component of the URL
 if the prefix is not nil then it will be PREFIX_<last path component>
 
 i.e. www.google.com/image.png
 without prefix fileName = image.png
 with prefix fileName = PREFIX_image.png
*/
- (NSString *)fileName;

@end

//-----------------------------------------------------------------------------------------------------------------