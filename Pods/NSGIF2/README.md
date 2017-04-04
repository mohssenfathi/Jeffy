![NSGIF2](https://raw.githubusercontent.com/metasmile/NSGIF2/master/title.png?v=2)

Create a GIF from the provided video file url.

*This repository has been separated from original repo along with some nontrivial different features, designs, and improvements. Please do diff each other, and visit [original repo](https://github.com/NSRare/NSGIF) for more information if you need.*

## Installation

There are 2 ways you can add NSGIF to your project:

### Manual

Simply import the 'NSGIF' into your project then import the following in the class you want to use it:
```objective-c
#import "NSGIF.h"
```      
### From CocoaPods

```ruby
pod "NSGIF2"
```

## Usage

Default request automatically set essential options such as the best frame count, delay time, output temp file name, or size. see interface file for more options.

### Write 1 line to export
```objective-c
[NSGIF create:[NSGIFRequest requestWithSourceVideo:tempVideoFileURL] completion:^(NSURL *GifURL) {
    //GifURL is to nil if it failed or stopped.
}];
```

### If you need more.
```objective-c
NSGIFRequest * request = [NSGIFRequest requestWithSourceVideo:tempVideoFileURL destination:gifFileURL];
request.progressHandler = ^(double progress, NSUInteger position, NSUInteger length, CMTime time, BOOL *stop, NSDictionary *frameProperties) {
    NSLog(@"%f - %lu - %lu - %lld - %@", progress, position, length, time.value, frameProperties);
};

[NSGIF create:request completion:^(NSURL *GifURL) {
    //GifURL is to nil if it failed or stopped.
}];
```

### Interrupt process for given request
```objective-c
request.progressHandler = ^(double progress, NSUInteger position, NSUInteger length, CMTime time, BOOL *stop, NSDictionary *frameProperties) {
    BOOL cancelationCondition = YES;
    if(cancelationCondition){
        *stop = YES;
    }
};
```

## Options
```objective-c
@interface NSGIFRequest : NSObject

/* required.
 * a file's url of source video */
@property(nullable, nonatomic) NSURL * sourceVideoFile;

/* optional.
 * defaults to nil.
 * automatically assign the file name of source video (ex: IMG_0000.MOV -> IMG_0000.gif)  */
@property(nullable, nonatomic) NSURL * destinationVideoFile;

/* optional but important.
 * Defaults to NSGIFScaleOptimize (not set).
 * This option will affect gif file size, memory usage and processing speed. */
@property(nonatomic, assign) NSGIFScale scalePreset;

/* optional but important.
 * Defaults to 4.
 * number of frames in seconds.
 * This option will affect gif file size, memory usage and processing speed. */
@property(nonatomic, assign) NSUInteger framesPerSecond;

/* optional but defaults is recommended.
 * Defaults is to not set.
 * How far along the video track we want to move, in seconds. It will automatically assign from duration of video and framesPerSecond. */
@property(nonatomic, assign) NSUInteger frameCount;

/* optional.
 * Defaults to 0,
 * the number of times the GIF will repeat. which means repeat infinitely. */
@property(nonatomic, assign) NSUInteger loopCount;

/* optional.
 * Defaults to 0.13.
 * unit is 10ms, 1/100s, the amount of time for each frame in the GIF.
 * This option will NOT affect gif file size, memory usage and processing speed. It affect only FPS. */
@property(nonatomic, assign) CGFloat delayTime;

/* optional.
 * Defaults is to not set. unit is seconds, which means unlimited */
@property(nonatomic, assign) NSTimeInterval maxDuration;

/* optional.
 * Defaults is nil */
@property (nonatomic, copy, nullable) NSGIFProgressHandler progressHandler;

/* gif creation job is now proceeding */
@property(atomic, readonly) BOOL proceeding;

- (NSGIFRequest * __nonnull)initWithSourceVideo:(NSURL * __nullable)fileURL;
+ (NSGIFRequest * __nonnull)requestWithSourceVideo:(NSURL * __nullable)fileURL;
+ (NSGIFRequest * __nonnull)requestWithSourceVideo:(NSURL * __nullable)fileURL destination:(NSURL * __nullable)videoFileURL;
+ (NSGIFRequest * __nonnull)requestWithSourceVideoForLivePhoto:(NSURL *__nullable)fileURL;
@end
```

## In the future, I will add a feature that can

* create from a provided photo url.
* perform simultaneous processing with provided specific chunk size.
* seek for specific point.
* generate infinite lengh of GIFs (Split with specific chunk size -> encoding -> merge each encoded piece of gifs.)
* use APIs which is pefectly similar with PhotosKit of iOS.

Pull requests are more than welcomed!

## License
Usage is provided under the [MIT License](http://http//opensource.org/licenses/mit-license.php). See LICENSE for the full details.
