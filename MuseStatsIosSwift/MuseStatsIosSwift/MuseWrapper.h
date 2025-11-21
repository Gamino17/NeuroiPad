//
//  MuseWrapper.h
//  Wrapper Objective-C para Muse SDK
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IXNMuse;
@class IXNMuseDataPacket;

@protocol MuseWrapperDelegate <NSObject>
@optional
- (void)museDiscovered:(NSString *)name macAddress:(NSString *)macAddress;
- (void)museConnectionChanged:(NSString *)state;
- (void)museDataReceived:(NSArray<NSNumber *> *)channels timestamp:(NSTimeInterval)timestamp type:(NSString *)type;
@end

@interface MuseWrapper : NSObject

@property (nonatomic, weak, nullable) id<MuseWrapperDelegate> delegate;

- (void)startScanning;
- (void)stopScanning;
- (void)connectToMuse:(NSString *)name;
- (void)disconnect;
- (void)startStreaming;
- (void)stopStreaming;

@end

NS_ASSUME_NONNULL_END




