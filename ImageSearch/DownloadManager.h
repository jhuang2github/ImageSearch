//
//  DownloadManager.h
//  ImageSearch
//
//  Created by Jingshu Huang on 9/28/14.
//  Copyright (c) 2014 HuangImage. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NUM_IMAGES_PER_REQUEST 8
#define DATA_KEY @"data"
#define ERROR_KEY @"error"


@protocol ImageSearchDelegate
- (void)parseResponse:(NSDictionary *)response;
@end


@interface DownloadManager : NSObject

+ (DownloadManager *)instance;
- (NSURL *)urlFromString:(NSString *)urlStr;
- (void)fetchGoogleImagesForQuery:(NSString*)query
                   withStartIndex:(int)startIndex
                         delegate:(id<ImageSearchDelegate>)deleg;

@end
