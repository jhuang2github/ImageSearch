//
//  DownloadManager.m
//  ImageSearch
//
//  Created by Jingshu Huang on 9/28/14.
//  Copyright (c) 2014 HuangImage. All rights reserved.
//
//
// Note: maybe we can do it with DownloadOperation : NSOperation
// https://github.com/objcio/issue-2-background-networking/blob/master/URLLoader/DownloadOperation.m
// https://github.com/rs/SDWebImage/blob/master/SDWebImage/SDWebImageDownloaderOperation.m
//

#import "DownloadManager.h"
#import "Image.h"

#define GOOGLE_IMAGE_API_STR \
    @"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=%@&imgsz=medium&rsz=%d&start=%d"


@interface DownloadManager()
//@property (nonatomic) NSMutableData *responseData;
@property (nonatomic, weak) id<ImageSearchDelegate> delegate;
@end


@implementation DownloadManager

+(DownloadManager *)instance {
    static DownloadManager *_instance = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        _instance = [[DownloadManager alloc] init];
    });

    return _instance;
}

- (void)fetchGoogleImagesForQuery:(NSString*)query
                   withStartIndex:(int)startIndex
                         delegate:(id<ImageSearchDelegate>)deleg {
    self.delegate = deleg;
    [self sendURLStringAsynchronously:[NSString stringWithFormat:
            GOOGLE_IMAGE_API_STR, query, NUM_IMAGES_PER_REQUEST, startIndex]];
}

- (NSURL *)urlFromString:(NSString *)urlStr {
    return [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
}

- (void)sendURLStringAsynchronously:(NSString *)urlStr {
    NSURLRequest *request = [NSURLRequest requestWithURL:[self urlFromString:urlStr]];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        [self.delegate parseResponse:(error ? @{ERROR_KEY:error} : @{DATA_KEY:data})];
    }];

}

//- (void)sendSynchronously:(NSString *)urlStr {
//    NSURLRequest *request = [NSURLRequest requestWithURL:[self urlFromString:urlStr]];
//	NSURLResponse *response = nil;
//	NSError *error = nil;
//	self.responseData = [[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error] mutableCopy];
//    [self.delegate parseResponse:@{DATA_KEY:self.responseData, ERROR_KEY:error}];
//}
//
//- (void)sendURLStringAsynchronously:(NSString *)urlStr {
//    NSURLRequest *request = [NSURLRequest requestWithURL:[self urlFromString:urlStr]];
//    [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
//    self.responseData = [[NSMutableData alloc] init];
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
//    [self.responseData appendData:data];
//}
//
//- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
//                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
//    return nil;
//}
//
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
//    [self.delegate parseResponse:@{DATA_KEY:self.responseData}];
//}
//
//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
//    [self.delegate parseResponse:@{ERROR_KEY:error}];
//}

@end
