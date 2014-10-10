//
//  DownloadManager.m
//  ImageSearch
//
//  Created by Jingshu Huang on 9/28/14.
//  Copyright (c) 2014 HuangImage. All rights reserved.
//

#import "DownloadManager.h"
#import "Image.h"

#define GOOGLE_IMAGE_API_STR \
    @"https://ajax.googleapis.com/ajax/services/search/images?v=1.0&q=%@&imgsz=medium&rsz=%d&start=%d"


@interface DownloadManager()
@property (nonatomic) NSMutableData *responseData;
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

- (void)sendSynchronously:(NSString *)urlStr {
    NSURLRequest *request = [NSURLRequest requestWithURL:[self urlFromString:urlStr]];
	NSURLResponse *response = nil;
	NSError *error = nil;
	self.responseData = [[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error] mutableCopy];
    [self.delegate parseResponse:@{DATA_KEY:self.responseData, ERROR_KEY:error}];
}

//The sendAsynchronousRequest method is a relatively new addition, arriving in iOS 5. In terms of best practice there's little other than style to differentiate between it and the data delegate methods other than that a request created with the latter can be cancelled and a request created with the former can't. However the tidiness and hence the readability and greater improbability of bugs of the block-based sendAsynchronousRequest arguably give it an edge if you know you're not going to want to cancel your connections.
//
//References to sendSynchronousRequest are probably remnants of pre-iOS 5 patterns. Anywhere you see a sendSynchronousRequest, a sendAsynchronousRequest could be implemented just as easily and so as to perform more efficiently. I'd guess it was included originally because sometimes you're adapting code that needs to flow in a straight line and because there were no blocks and hence no 'essentially a straight line' way to implement an asynchronous call. I really can't think of any good reason to use it now.
- (void)sendURLStringAsynchronously:(NSString *)urlStr {
    NSURLRequest *request = [NSURLRequest requestWithURL:[self urlFromString:urlStr]];
    [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
//    [[NSURLConnection connectionWithRequest:request delegate:self]];
//    [NSURLConnection sendAsynchronousRequest:request
//                                       queue:(NSOperationQueue*)
//                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
//    }]
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.delegate parseResponse:@{DATA_KEY:self.responseData}];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.delegate parseResponse:@{DATA_KEY:self.responseData, ERROR_KEY:error}];
}

@end
