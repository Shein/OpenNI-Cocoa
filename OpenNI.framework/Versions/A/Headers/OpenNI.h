//
//  OpenNICocoa.h
//  OpenNICocoa
//
//  Created by Daniel Shein on 1/17/12.
//  Copyright (c) 2012 LoFT. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma warning(push,0)
#import <XnOS.h>
#import <XnCppWrapper.h>
#import <XnOpenNI.h>
#import <XnCodecIDs.h>
#import <XnVNite.h>
#pragma warning(pop)

#import "Point3D.h"

typedef enum {
    GestureTypeClick,
    GestureTypeWave,
    GestureTypeSwipeLeft,
    GestureTypeSwipeRight,    
    GestureTypeRaiseHand
} GestureType;


@protocol OpenNIDelegate <NSObject>

@required

-(void)openNiInitCompleteWithStatus:(NSNumber *)_status andError:(NSError*)_error;

@optional

-(void)frameReady;

-(void)userDidEnterWithId:(NSNumber *)_nId;
-(void)userDidLeaveWithId:(NSNumber *)_nId;

-(void)handDidBeginAt:(NSDictionary *)_point forUserId:(NSNumber *)_nId;
-(void)handDidMoveAt:(NSDictionary *)_point forUserId:(NSNumber *)_nId;
-(void)handDidStopForUserId:(NSNumber *)_nId;

-(void)gestureRecognizedAt:(NSDictionary*)_point withName:(NSString *)_gestureName;

@end

@interface OpenNI : NSObject
{
    //Content Variables
    const XnDepthPixel *depthMap;
    const XnUInt8 *rgb;
    const XnLabel *userLabelsMap;
    
    xn::DepthMetaData depthMetaData;
    xn::ImageMetaData imageMetaData;
    xn::SceneMetaData sceneMetaData;
    
    CGSize fulleResolution, croppedResolution, offset;
}

@property (readonly) const XnDepthPixel *depthMap;
@property (readonly) const XnUInt8 *rgb;
@property (readonly) const XnLabel *userLabelsMap;
@property (readonly) CGSize fulleResolution, croppedResolution, offset;

+(OpenNI*)instance;
-(void)addDelegate:(id)_delegate;
-(void)removeDelegate:(id)_delegate;

//OpenNI Methods
-(void)initOpenNiWithConfigFile:(NSString*)_pathToConfigFile;
-(void)initOpenNi;
-(XnStatus)startGeneratingFrames;
-(void)stopGeneratingFrames;

-(void)startRecordingToFile:(NSString*)_filePath;
-(void)stopRecording;

-(void)startTrackingHandAtPosition:(Point3D*)_point;
-(void)stopTrakcingHandWithUserId:(XnUserID)_userId;

-(void)startDetectingGesture:(GestureType)_gesture;
-(void)stopDetectingGesture:(GestureType)_gesture;

@end
