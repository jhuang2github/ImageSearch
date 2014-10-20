//
//  ImageManager.h
//  ImageSearch
//
//  Created by Jingshu Huang on 10/19/14.
//  Copyright (c) 2014 HuangImage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadManager.h"

#define kImageManagerAddedContentNotification @"imageSearch.ImageManagerAddedContent"

typedef void (^ThumbnailDownloadCompletionBlock)(void);


@class Image;

@interface ImageManager : NSObject <ImageSearchDelegate>

+ (instancetype)instance;
- (void)loadImageURLsWithKeywords:(NSString *)keywords startIndex:(int)startIndex;
- (void)loadThumbnailImage:(Image *)img completionBlock:(ThumbnailDownloadCompletionBlock)completionBlock;
- (void)cleanup;
- (int)numImages;
- (Image *)imageAtIndex:(int)index;

@end
