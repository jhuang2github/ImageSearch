//
//  ImageManager.m
//  ImageSearch
//
//  Created by Jingshu Huang on 10/19/14.
//  Copyright (c) 2014 HuangImage. All rights reserved.
//

#import "Image.h"
#import "ImageManager.h"


@interface ImageManager()

@property (nonatomic) NSMutableArray *images;
@property (nonatomic) int lastPageStartIndex;
@property (nonatomic) int prevStartIndex;

// debug(jhuang):
@property (nonatomic) dispatch_queue_t serialQueue;
@property (nonatomic) dispatch_queue_t concurQueue;

@end


@implementation ImageManager

+ (ImageManager *)instance {
    static ImageManager *_instance = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^(void){
        if (!_instance) {
            _instance = [[ImageManager alloc] init];
        }
    });

    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // debug(jhuang):
        self.serialQueue = dispatch_queue_create("mySerialQueue", DISPATCH_QUEUE_SERIAL);
        self.concurQueue = dispatch_queue_create("myConcurrentQueue", DISPATCH_QUEUE_CONCURRENT);
        
        self.lastPageStartIndex = -1;
        self.prevStartIndex = INT_MIN;
        self.images = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void)cleanup {
    [self.images removeAllObjects];
}

- (void)loadImageURLsWithKeywords:(NSString *)keywords startIndex:(int)startIndex {
    if (keywords.length > 0
        && startIndex >= self.prevStartIndex + NUM_IMAGES_PER_REQUEST
        && (startIndex <= self.lastPageStartIndex || self.lastPageStartIndex < 0)) {
        
        [[DownloadManager instance] fetchGoogleImagesForQuery:keywords
                                               withStartIndex:startIndex
                                                     delegate:self];
        self.prevStartIndex = startIndex;
    }
}

- (int)numImages {
    return [self.images count];
}

- (Image *)imageAtIndex:(int)index {
    return [self.images objectAtIndex:index];
}

#pragma mark - ImageSearchDelegate

- (void)parseResponse:(NSDictionary *)response {
    NSData *data = response[DATA_KEY];
    if (data.length == 0) {
        NSLog(@"empty response.");
        return;
    }
    __block NSError *error = response[ERROR_KEY];
    if (error) {
        NSLog(@"response error: %@", error);
        return;
    }
    
    // Parse the data in the background.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void) {
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:NSJSONWritingPrettyPrinted
                                                                       error:&error];
        
        if (error) {
            NSLog(@"json serialization error = %@, response = %@", error, responseDict);
            return;
        }
        
        id responseData = responseDict[@"responseData"];
        if (![responseData isKindOfClass:[NSDictionary class]]) {
            NSLog(@"json serialization error = %@, response = %@", error, responseDict);
            return;
        }
        
        NSArray *resultArray = responseData[@"results"];
        NSDictionary *cursor = responseData[@"cursor"];
        
        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            [self setupUrlData:resultArray cursor:cursor];

            [[NSNotificationCenter defaultCenter] postNotificationName:kImageManagerAddedContentNotification
                                                                object:self
                                                              userInfo:nil];
        });
    });
}

- (void)setupUrlData:(NSArray *)resultArray cursor:(NSDictionary *)cursor {
    DownloadManager *dwnManagr = [DownloadManager instance];

    for (NSDictionary *entry in resultArray) {
        Image *img = [[Image alloc] init];
        img.tbUrl = [dwnManagr urlFromString:entry[@"tbUrl"]];
        img.url = [dwnManagr urlFromString:entry[@"url"]];
        [self.images addObject:img];
    }
    
    if (cursor && [cursor isKindOfClass:[NSDictionary class]]) {
        NSDictionary *page = [cursor[@"pages"] lastObject];
        self.lastPageStartIndex = [page[@"start"] intValue];
    }
}

- (void)loadThumbnailImage:(Image *)img completionBlock:(ThumbnailDownloadCompletionBlock)completionBlock {
    if (img.tbImage) {
        completionBlock();
        return;
    }

    // The image is not loaded yet. Load it in the background. Other global (concurrent) dispatch
    // queue are: background, low, high, default.
    dispatch_queue_t globalBGQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(globalBGQueue, ^(void) {
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:img.tbUrl]];

        dispatch_sync(dispatch_get_main_queue(), ^(void) {
            img.tbImage = image;
            completionBlock();
        });
    });

//    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
//    [queue addOperationWithBlock:^{
//        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:img.tbUrl]];
//
//        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//            img.tbImage = image;
//            completionBlock();
//        }];
//    }];
}

//- (void)postContentAddedNotification {
//    static NSNotification *notification = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        notification = [NSNotification notificationWithName:kImageManagerAddedContentNotification object:nil];
//    });
//    
//    [[NSNotificationQueue defaultQueue] enqueueNotification:notification
//                                               postingStyle:NSPostASAP
//                                               coalesceMask:NSNotificationCoalescingOnName
//                                                   forModes:nil];
//}

@end
