//
//  OpenNIPrivateHeaders.h
//  OpenNICocoa
//
//  Created by Daniel Shein on 1/17/12.
//  Copyright (c) 2012 LoFT. All rights reserved.
//

#ifndef OpenNICocoa_OpenNIPrivateHeaders_h
#define OpenNICocoa_OpenNIPrivateHeaders_h


typedef enum OpenNiState
{
    OpenNiUnInited,
    OpenNiInited,
    OpenNiIniting,
    OpenNiWorking
} OpenNiState;

NSMutableSet *delegates;
NSTimer *frameTimer;
OpenNiState state;

//OpenNI Variables
xn::Context xnContext;
xn::ScriptNode xnScriptNode;
xn::DepthGenerator xnDepthGenerator;
xn::ImageGenerator xnImageGenerator;

xn::UserGenerator xnUserGenerator;
xn::GestureGenerator xnGestureGenerator;
xn::HandsGenerator xnHandGenerator;
xn::SceneAnalyzer xnSceneAnalyzer;

xn::Recorder *xnRecorder;


// User Detection Callbacks
void XN_CALLBACK_TYPE User_NewUser(xn::UserGenerator &generator, XnUserID nId, void* pCookie);
void XN_CALLBACK_TYPE User_LostUser(xn::UserGenerator &generator, XnUserID nId, void* pCookie);


// Gesture Callbacks
void XN_CALLBACK_TYPE Gesture_Recognized(xn::GestureGenerator &generator, const XnChar *strGesture, const XnPoint3D *pPoistion, const XnPoint3D *pEndPosition, void *pCookie);
void XN_CALLBACK_TYPE Gesture_Process(xn::GestureGenerator &generator, const XnChar *strGesture, const XnPoint3D *pPosition, XnFloat fProgress, void *pCookie);


// Hand Detection Callbacks
void XN_CALLBACK_TYPE Hand_Created(xn::HandsGenerator &generator, XnUserID user, const XnPoint3D *pPosition, XnFloat fTime, void *pCookie);
void XN_CALLBACK_TYPE Hand_Update(xn::HandsGenerator &generator, XnUserID user, const XnPoint3D *pPosition, XnFloat fTime, void *pCookie);
void XN_CALLBACK_TYPE Hand_Lost(xn::HandsGenerator &generator, XnUserID user, XnFloat fTime, void *pCookie);


// Skeleton Callbacks
void XN_CALLBACK_TYPE Pose_Detected(xn::PoseDetectionCapability &pose, const XnChar* strPose, XnUserID nId, void *pCookie);
void XN_CALLBACK_TYPE Calibration_Start(xn::SkeletonCapability &capability, XnUserID nId, void *pCookie);
void XN_CALLBACK_TYPE Calibration_End(xn::SkeletonCapability &capability, XnUserID nId, XnBool bSuccess, void *pCookie);


@interface OpenNI (Internals)

-(void)performSelector:(SEL)_selector onDelegate:(id)_delegate withObject:(id)_object;
-(void)performSelector:(SEL)_selector onDelegates:(NSSet *)_delegates withObject:(id)_object;

-(NSString*)stringForGestureType:(GestureType)_gestureType;

@end


#endif
