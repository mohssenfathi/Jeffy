//
//  NSGIF.m
//  
//  Created by Sebastian Dobrincu
//

#import "NSGIF.h"

// Declare constants
#define prefix     @"NSGIF"
#define timeInterval @(600)
#define tolerance    @(0.01)

CG_INLINE CGFloat
NSGIFScaleRatio(NSGIFScale scalePhase, CGSize sourceSize)
{
    switch (scalePhase){
        case NSGIFScaleVeryLow:
            return .2f;
        case NSGIFScaleLow:
            return .3f;
        case NSGIFScaleMedium:
            return .5f;
        case NSGIFScaleHigh:
            return .7f;
        case NSGIFScaleOriginal:
            return 1;
        default:{
            NSGIFScale targetScalePhase = NSGIFScaleMedium;
            if (sourceSize.width >= 1200 || sourceSize.height >= 1200)
                targetScalePhase = NSGIFScaleVeryLow;
            else if (sourceSize.width >= 800 || sourceSize.height >= 800)
                targetScalePhase = NSGIFScaleLow;
            else if (sourceSize.width >= 400 || sourceSize.height >= 400)
                targetScalePhase = NSGIFScaleMedium;
            else if (sourceSize.width < 400|| sourceSize.height < 400)
                targetScalePhase = NSGIFScaleHigh;
            return NSGIFScaleRatio(targetScalePhase, sourceSize);
        }
    }
}

CGImageRef createImageWithScale(CGImageRef imageRef, CGFloat scale) {

    #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    CGSize newSize = CGSizeMake(CGImageGetWidth(imageRef)*scale, CGImageGetHeight(imageRef)*scale);
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));

    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return nil;
    }

    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);

    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);

    //Release old image
    CFRelease(imageRef);
    // Get the resized image from the context and a UIImage
    imageRef = CGBitmapContextCreateImage(context);

    UIGraphicsEndImageContext();
    #endif

    return imageRef;
}

@interface NSGIFRequest()
@property(atomic, assign) BOOL proceeding;
@end

@implementation NSGIFRequest

- (instancetype)init {
    self = [super init];
    if (self) {
        self.framesPerSecond = 4;
        self.delayTime = 0.13f;
    }
    return self;
}

- (instancetype)initWithSourceVideo:(NSURL *)fileURL {
    self = [self init];
    if (self) {
        self.sourceVideoFile = fileURL;
    }
    return self;
}

+ (instancetype)requestWithSourceVideo:(NSURL *)fileURL {
    return [[self alloc] initWithSourceVideo:fileURL];
}

+ (instancetype)requestWithSourceVideo:(NSURL *)fileURL destination:(NSURL *)videoFileURL {
    NSGIFRequest * request = [[self alloc] initWithSourceVideo:fileURL];
    request.destinationVideoFile = videoFileURL;
    return request;
}

+ (instancetype)requestWithSourceVideoForLivePhoto:(NSURL *__nullable)fileURL {
    NSGIFRequest * request = [[NSGIFRequest alloc] initWithSourceVideo:fileURL];
    request.delayTime = 0.1f;
    request.framesPerSecond = 8;
    return request;
}

- (void)cancelIfNeeded {
    //TODO: interrupt current proceeding jobs of request.
}

- (NSURL *)destinationVideoFile {
    if(_destinationVideoFile){
        return _destinationVideoFile;
    }
    NSAssert(self.sourceVideoFile, @"URL of a source video required if didn't provide destination url.");
    return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[prefix stringByAppendingPathExtension:@"gif"]]];
}

- (void)assert{
    NSParameterAssert(self.sourceVideoFile);
    NSAssert(self.framesPerSecond>0, @"framesPerSecond must be higer than 0.");
}
@end

@implementation NSGIF

#pragma mark - Public methods
+ (void)create:(NSGIFRequest *__nullable)request completion:(void (^ __nullable)(NSURL *__nullable))completionBlock {
    [request assert];

    // Create properties dictionaries
    NSDictionary *fileProperties = [self filePropertiesWithLoopCount:request.loopCount];
    NSDictionary *frameProperties = [self framePropertiesWithDelayTime:request.delayTime];

    AVURLAsset *asset = [AVURLAsset assetWithURL:request.sourceVideoFile];
    NSArray * assetTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    NSAssert(assetTracks.count,@"Not found any AVMediaTypeVideo in AVURLAsset which fetched from given sourceVideo file url");

    // set result output scale ratio
    CGFloat outputScale = NSGIFScaleRatio(request.scalePreset, ((AVAssetTrack *)assetTracks[0]).naturalSize);

    // Get the length of the video in seconds
    CGFloat videoLength = (CGFloat)asset.duration.value/asset.duration.timescale;

    // Clip videoLength via given max duration if needed
    if(request.maxDuration > 0){
        videoLength = (CGFloat)MIN(request.maxDuration, videoLength);
    }

    // Automatically set framecount by given framesPerSecond
    NSUInteger frameCount = request.frameCount ?: (NSUInteger) (videoLength * request.framesPerSecond);

    // How far along the video track we want to move, in seconds.
    CGFloat increment = (CGFloat)videoLength/frameCount;

    // Add frames to the buffer
    NSMutableArray *timePoints = [NSMutableArray array];
    for (int currentFrame = 0; currentFrame<frameCount; ++currentFrame) {
        CGFloat seconds = (CGFloat)increment * currentFrame;
        CMTime time = CMTimeMakeWithSeconds(seconds, [timeInterval intValue]);
        [timePoints addObject:[NSValue valueWithCMTime:time]];
    }

    // Prepare group for firing completion block
    dispatch_group_t gifQueue = dispatch_group_create();
    dispatch_group_enter(gifQueue);

    __block NSURL *gifURL;

    request.proceeding = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        gifURL = [self createGIFforTimePoints:timePoints
                                      fromURL:request.sourceVideoFile
                                        toURL:request.destinationVideoFile
                               fileProperties:fileProperties
                              frameProperties:frameProperties
                                   frameCount:frameCount
                                  outputScale:outputScale
                                     progress:request.progressHandler];

        dispatch_group_leave(gifQueue);
    });

    dispatch_group_notify(gifQueue, dispatch_get_main_queue(), ^{
        // Return GIF URL
        request.proceeding = NO;
        completionBlock(gifURL);
        gifURL = nil;
        request.progressHandler = nil;
    });
}


#pragma mark - Base methods

+ (NSURL *)createGIFforTimePoints:(NSArray *)timePoints
                          fromURL:(NSURL *)url
                            toURL:(NSURL *)destFileURL
                   fileProperties:(NSDictionary *)fileProperties
                  frameProperties:(NSDictionary *)frameProperties
                       frameCount:(NSUInteger)frameCount
                      outputScale:(CGFloat)outputScale
                         progress:(NSGIFProgressHandler)handler{

    NSParameterAssert(timePoints);
    NSParameterAssert(url);
    NSParameterAssert(destFileURL);
    NSParameterAssert(fileProperties);
    NSParameterAssert(frameProperties);

    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)destFileURL, kUTTypeGIF , frameCount, NULL);

    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    
    CMTime tol = CMTimeMakeWithSeconds([tolerance floatValue], [timeInterval intValue]);
    generator.requestedTimeToleranceBefore = tol;
    generator.requestedTimeToleranceAfter = tol;
    
    NSError *error = nil;
    CGImageRef previousImageRefCopy = nil;
    NSUInteger lengthOfTimePoints = timePoints.count;
    BOOL stop = NO;
    for (NSValue *time in timePoints) {
        CGImageRef imageRef;
        
        #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
            if(outputScale==1){
                imageRef = [generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error];
            }else{
                imageRef = createImageWithScale([generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error], outputScale);
            }
        #elif TARGET_OS_MAC
            imageRef = [generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error];
        #endif
        
        NSAssert(!error, @"Error copying image to create gif");
        if (error) {
            NSLog(@"Error copying image: %@", error);
        }
        if (imageRef) {
            CGImageRelease(previousImageRefCopy);
            previousImageRefCopy = CGImageCreateCopy(imageRef);
        } else if (previousImageRefCopy) {
            imageRef = CGImageCreateCopy(previousImageRefCopy);
        } else {
            NSLog(@"Error copying image and no previous frames to duplicate");
            return nil;
        }
        CGImageDestinationAddImage(destination, imageRef, (__bridge CFDictionaryRef)frameProperties);
        CGImageRelease(imageRef);
        NSUInteger position = [timePoints indexOfObject:time]+1;
        !handler?:handler((CGFloat)position/lengthOfTimePoints,position, lengthOfTimePoints, [time CMTimeValue], &stop, frameProperties);
        if(stop){
            break;
        }
    }
    CGImageRelease(previousImageRefCopy);
    
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    // Finalize the GIF
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to finalize GIF destination: %@", error);
        if (destination != nil) {
            CFRelease(destination);
        }
        return nil;
    }
    CFRelease(destination);
    
    return destFileURL;
}

#pragma mark - Properties

+ (NSDictionary *)filePropertiesWithLoopCount:(NSUInteger)loopCount {
    return @{(NSString *)kCGImagePropertyGIFDictionary:
                @{(NSString *)kCGImagePropertyGIFLoopCount: @(loopCount)}
             };
}

+ (NSDictionary *)framePropertiesWithDelayTime:(CGFloat)delayTime {

    return @{(NSString *)kCGImagePropertyGIFDictionary:
                @{(NSString *)kCGImagePropertyGIFDelayTime: @(delayTime)},
                (NSString *)kCGImagePropertyColorModel:(NSString *)kCGImagePropertyColorModelRGB
            };
}
@end
