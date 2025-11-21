//
//  MuseWrapper.m
//  Wrapper Objective-C para Muse SDK
//

#import "MuseWrapper.h"
#import <Muse/Muse.h>

@interface MuseWrapper () <IXNMuseListener, IXNMuseConnectionListener, IXNMuseDataListener>

@property (nonatomic, strong) IXNMuseManagerIos *museManager;
@property (nonatomic, strong) NSMutableDictionary<NSString *, IXNMuse *> *museMap;
@property (nonatomic, strong, nullable) IXNMuse *connectedMuse;

@end

@implementation MuseWrapper

- (instancetype)init {
    self = [super init];
    if (self) {
        _museManager = [[IXNMuseManagerIos alloc] init];
        _museMap = [NSMutableDictionary dictionary];
        
        [_museManager setMuseListener:self];
        [_museManager removeFromListAfter:10];
    }
    return self;
}

#pragma mark - Public Methods

- (void)startScanning {
    NSLog(@"🔍 Starting Muse scan");
    [self.museManager stopListening];
    [self.museManager startListening];
}

- (void)stopScanning {
    NSLog(@"🛑 Stopping scan");
    [self.museManager stopListening];
}

- (void)connectToMuse:(NSString *)name {
    NSLog(@"🔗 Connecting to %@", name);
    
    IXNMuse *muse = self.museMap[name];
    if (!muse) {
        NSLog(@"❌ Muse not found: %@", name);
        return;
    }
    
    [self.museManager stopListening];
    [muse unregisterAllListeners];
    
    [muse registerConnectionListener:self];
    [muse registerDataListener:self type:IXNMuseDataPacketTypeEeg];
    [muse setPreset:IXNMusePresetPreset21];
    
    [muse runAsynchronously];
    self.connectedMuse = muse;
}

- (void)disconnect {
    if (self.connectedMuse) {
        NSLog(@"🔌 Disconnecting");
        [self.connectedMuse disconnect];
        [self.connectedMuse unregisterAllListeners];
        self.connectedMuse = nil;
    }
}

- (void)startStreaming {
    NSLog(@"▶️ Streaming started");
}

- (void)stopStreaming {
    NSLog(@"⏹ Streaming stopped");
}

#pragma mark - IXNMuseListener

- (void)museListChanged {
    NSArray<IXNMuse *> *muses = [self.museManager getMuses];
    
    for (IXNMuse *muse in muses) {
        NSString *name = [muse getName];
        if (!self.museMap[name]) {
            self.museMap[name] = muse;
            
            NSLog(@"📱 Found: %@ (%@)", name, [muse getMacAddress]);
            
            if ([self.delegate respondsToSelector:@selector(museDiscovered:macAddress:)]) {
                [self.delegate museDiscovered:name macAddress:[muse getMacAddress]];
            }
        }
    }
}

#pragma mark - IXNMuseConnectionListener

- (void)receiveMuseConnectionPacket:(IXNMuseConnectionPacket *)packet muse:(IXNMuse * _Nullable)muse {
    IXNConnectionState prevState = [packet previousConnectionState];
    IXNConnectionState currState = [packet currentConnectionState];
    
    NSLog(@"🔄 Connection: %ld → %ld", (long)prevState, (long)currState);
    
    NSString *stateString = @"unknown";
    if (currState == IXNConnectionStateConnected) {
        stateString = @"connected";
    } else if (currState == IXNConnectionStateConnecting) {
        stateString = @"connecting";
    } else if (currState == IXNConnectionStateDisconnected) {
        stateString = @"disconnected";
    }
    
    if ([self.delegate respondsToSelector:@selector(museConnectionChanged:)]) {
        [self.delegate museConnectionChanged:stateString];
    }
}

#pragma mark - IXNMuseDataListener

- (void)receiveMuseDataPacket:(IXNMuseDataPacket * _Nullable)packet muse:(IXNMuse * _Nullable)muse {
    if (!packet) return;
    
    if ([packet packetType] == IXNMuseDataPacketTypeEeg) {
        NSMutableArray<NSNumber *> *channels = [NSMutableArray array];
        [channels addObject:@([packet getEegChannelValue:IXNEegEEG1])]; // TP9
        [channels addObject:@([packet getEegChannelValue:IXNEegEEG2])]; // AF7
        [channels addObject:@([packet getEegChannelValue:IXNEegEEG3])]; // AF8
        [channels addObject:@([packet getEegChannelValue:IXNEegEEG4])]; // TP10
        
        NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
        
        if ([self.delegate respondsToSelector:@selector(museDataReceived:timestamp:type:)]) {
            [self.delegate museDataReceived:channels timestamp:timestamp type:@"EEG"];
        }
    }
}

- (void)receiveMuseArtifactPacket:(IXNMuseArtifactPacket *)packet muse:(IXNMuse * _Nullable)muse {
    // Artifacts handling if needed
}

@end

