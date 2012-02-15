//
//  OpenNICocoa.m
//  OpenNICocoa
//
//  Created by Daniel Shein on 1/17/12.
//  Copyright (c) 2012 LoFT. All rights reserved.
//

#import "OpenNI.h"
#import "OpenNIPrivateHeaders.h"
#import "Point3D.h"

@implementation OpenNI

@synthesize rgb;
@synthesize userLabelsMap;
@synthesize fulleResolution, croppedResolution, offset;


+(OpenNI*)instance{
	static OpenNI * instance = NULL;
    
	@synchronized(self)
	{
		if (instance == NULL) {
			
			instance = [[self alloc] init];
            delegates = [[NSMutableSet alloc] init];
            state = OpenNiUnInited;
		}
	}
	
	return(instance);
}

-(void)dealloc
{
    [self stopGeneratingFrames];
    xnContext.Shutdown();
    xnContext.Release();
    
    [frameTimer invalidate];
    [frameTimer release], frameTimer = nil;
    [delegates release], delegates = nil;
}

-(void)addDelegate:(id)_delegate
{
    [delegates addObject:_delegate];
}

-(void)removeDelegate:(id)_delegate
{
    [delegates removeObject:_delegate];
}

-(void)performSelector:(SEL)_selector onDelegate:(id)_delegate withObject:(id)_object
{
    if (_delegate != nil && [_delegate respondsToSelector:_selector]) {
        [_delegate performSelector:_selector withObject:_object];
    }
}

-(void)performSelector:(SEL)_selector onDelegates:(NSSet *)_delegates withObject:(id)_object
{
    for (id delegate in _delegates) {
        [self performSelector:_selector onDelegate:delegate withObject:_object];
    }
}

#pragma mark - Interface Methods

-(BOOL)didSucceed:(XnStatus)_rc withLog:(BOOL)_log
{
    if (_rc != XN_STATUS_OK) {
        if (_log) {
            NSLog(@"OpenNi Error: %s", xnGetStatusString(_rc));
        }
        return NO;
    }
    
    return YES;
}

-(XnStatus)startGeneratingFrames
{
    XnStatus rc;
    
    rc = xnContext.StartGeneratingAll();
    if (rc != XN_STATUS_OK) {
        NSLog(@"Failed starting generation #10007: %s", xnGetStatusString(rc));
        return rc;
    }
    
    
    frameTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:1.0f/100.0f target:self selector:@selector(updateFrame:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:frameTimer forMode:NSDefaultRunLoopMode];
    [[NSRunLoop mainRunLoop] addTimer:frameTimer forMode:NSEventTrackingRunLoopMode];
    
    return rc;
}

-(void)stopGeneratingFrames
{
    xnContext.StopGeneratingAll();
    [frameTimer invalidate];
    [frameTimer release];
}


-(void)startRecordingToFile:(NSString*)_filePath
{
    XnStatus rc;
    xnRecorder = new xn::Recorder();
    
    rc = xnContext.CreateAnyProductionTree(XN_NODE_TYPE_RECORDER, NULL, *xnRecorder);
    if (rc != XN_STATUS_OK) {
        NSLog(@"Failed starting generation #30001: %s", xnGetStatusString(rc));
        return;
    }
    
    rc = xnRecorder->SetDestination( XN_RECORD_MEDIUM_FILE, [_filePath cStringUsingEncoding:NSUTF8StringEncoding]);
    //TODO: test rc
    
    rc = xnRecorder->AddNodeToRecording(xnDepthGenerator, XN_CODEC_16Z_EMB_TABLES);
    //TODO: test rc
    
    rc = xnRecorder->AddNodeToRecording(xnImageGenerator, XN_CODEC_JPEG);
    //TODO: test rc
    
}

-(void)stopRecording
{
    if (xnRecorder != NULL) {
        xnRecorder->RemoveNodeFromRecording(xnDepthGenerator);
        xnRecorder->RemoveNodeFromRecording(xnImageGenerator);
        xnRecorder->Release();
        delete xnRecorder;
    }
}


#pragma mark - OpenNI Methods


-(void)initOpenNi
{
    //Load default config file
    NSBundle *bundle = [NSBundle bundleForClass:[OpenNI class]];
    NSString *configPath = [bundle pathForResource:@"Config" ofType:@"xml"];
    
    [self initOpenNiWithConfigFile:configPath];
}

-(void)initOpenNiWithConfigFile:(NSString*)_pathToConfigFile
{    
    if (state != OpenNiUnInited) { return; }
    
    state = OpenNiIniting;
    
    __block XnStatus rc;
    __block NSError *error;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        
        xn::EnumerationErrors errors;
        
        rc = xnContext.InitFromXmlFile([_pathToConfigFile cStringUsingEncoding:NSUTF8StringEncoding], xnScriptNode, &errors);
        
        if (rc != XN_STATUS_OK) {
            NSLog(@"Failed initing OpenNI #10001: %s", xnGetStatusString(rc));
            return;
        }
        
        //Get DepthGenerator
        rc = xnContext.FindExistingNode(XN_NODE_TYPE_DEPTH, xnDepthGenerator);
        if (rc != XN_STATUS_OK) {
            NSLog(@"Failed getting depth generator #10002: %s", xnGetStatusString(rc));
            return;
        }
        
        //Get DepthGenerator
        rc = xnContext.FindExistingNode(XN_NODE_TYPE_IMAGE, xnImageGenerator);
        if (rc != XN_STATUS_OK) {
            NSLog(@"Failed getting image generator #10003: %s", xnGetStatusString(rc));
            return;
        }    
        
        xnDepthGenerator.GetMetaData(depthMetaData);
        
        fulleResolution = CGSizeMake((CGFloat)depthMetaData.FullXRes(), (CGFloat)depthMetaData.FullYRes());
        croppedResolution = CGSizeMake((CGFloat)depthMetaData.XRes(), (CGFloat)depthMetaData.YRes());    
        offset = CGSizeMake((CGFloat) depthMetaData.XOffset(), (CGFloat) depthMetaData.YOffset());
        
        xnContext.FindExistingNode(XN_NODE_TYPE_SCENE, xnSceneAnalyzer);
        
        //Register Callbacks for NITE
        rc = xnUserGenerator.Create(xnContext);
        if (rc != XN_STATUS_OK) {
            NSLog(@"Failed creating user generator #20001: %s", xnGetStatusString(rc));
        }

        XnCallbackHandle h1;
        rc = xnUserGenerator.RegisterUserCallbacks(User_NewUser, User_LostUser, NULL, h1);
        if (rc != XN_STATUS_OK) {
            NSLog(@"Failed registering user callbacks #20002: %s", xnGetStatusString(rc));
        } 
        
        XnCallbackHandle h2;
        rc = xnUserGenerator.GetPoseDetectionCap().RegisterToPoseCallbacks(Pose_Detected, NULL, NULL, h2);
        if (rc != XN_STATUS_OK) {
            NSLog(@"Failed registering Pose callbacks #30001: %s", xnGetStatusString(rc));
        } 


        XnCallbackHandle h3;
        rc = xnUserGenerator.GetSkeletonCap().RegisterCalibrationCallbacks(Calibration_Start, Calibration_End, NULL, h3);
        if (rc != XN_STATUS_OK) {
            NSLog(@"Failed registering Pose callbacks #30001: %s", xnGetStatusString(rc));
        }         
        xnUserGenerator.GetSkeletonCap().SetSkeletonProfile(XN_SKEL_PROFILE_ALL);
        

        XnCallbackHandle h4;
        xnGestureGenerator.Create(xnContext);
        rc = xnGestureGenerator.RegisterGestureCallbacks(Gesture_Recognized, Gesture_Process, NULL, h4);
        if (rc != XN_STATUS_OK) {
            NSLog(@"Failed registering Gesture callbacks #40001: %s", xnGetStatusString(rc));
        }         
        xnGestureGenerator.AddGesture("Click", NULL);
        
        XnCallbackHandle h5;
        rc = xnHandGenerator.Create(xnContext);
        if (rc != XN_STATUS_OK) {
            NSLog(@"Failed getting hand generator #50001: %s", xnGetStatusString(rc));
        }

        xnHandGenerator.RegisterHandCallbacks(Hand_Created, Hand_Update, Hand_Lost, NULL, h5);
        

    }];
    
    [operation setCompletionBlock:^{
        
        if (rc == XN_STATUS_OK) {
            state = OpenNiInited;
        } else {
            state = OpenNiUnInited;
        }
        
        for (id delegate in delegates) {
            if (delegate != nil && [delegate respondsToSelector:@selector(openNiInitCompleteWithStatus:andError:)]) {
                [delegate performSelector:@selector(openNiInitCompleteWithStatus:andError:) withObject:[NSNumber numberWithInt:rc] withObject:error];
            } 
        }
    }];
    
    [queue addOperation:operation];
}


-(void)updateFrame:(NSTimer*)_timer
{
    XnStatus rc = xnContext.WaitOneUpdateAll(xnDepthGenerator);
    if (rc != XN_STATUS_OK) {
        NSLog(@"Failed updating frame from sensor #10005: %s", xnGetStatusString(rc));
        return;
    }
    
    xnDepthGenerator.GetMetaData(depthMetaData);
    xnImageGenerator.GetMetaData(imageMetaData);
    xnSceneAnalyzer.GetMetaData(sceneMetaData);
    
    depthMap = depthMetaData.Data();
    rgb = imageMetaData.Data();
    userLabelsMap = sceneMetaData.Data();    
    
    for (id delegate in delegates){
        if (delegate != nil && [delegate respondsToSelector:@selector(frameReady)]) {
            [delegate performSelector:@selector(frameReady)];
        }
    }    
}


#pragma mark - NITE Events Methods

void XN_CALLBACK_TYPE User_NewUser(xn::UserGenerator &generator, XnUserID nId, void* pCookie)
{    
    for (id delegate in delegates){
        if (delegate != nil && [delegate respondsToSelector:@selector(userDidEnterWithId:)]) {
            [delegate performSelector:@selector(userDidEnterWithId:) withObject:[NSNumber numberWithInt:nId]];
        }
    }   
    
    //TODO: add toggle if to detect Pose
//    xnUserGenerator.GetPoseDetectionCap().StartPoseDetection("Psi", nId);
//    NSLog(@"Detecting Pose");
}


void XN_CALLBACK_TYPE User_LostUser(xn::UserGenerator &generator, XnUserID nId, void* pCookie)
{
    for (id delegate in delegates){
        if (delegate != nil && [delegate respondsToSelector:@selector(userDidLeaveWithId:)]) {
            [delegate performSelector:@selector(userDidLeaveWithId:) withObject:[NSNumber numberWithInt:nId]];
        }
    }   
}



void XN_CALLBACK_TYPE Gesture_Recognized(xn::GestureGenerator &generator, const XnChar *strGesture, const XnPoint3D *pPosition, const XnPoint3D *pEndPosition, void *pCookie)
{
    for (id delegate in delegates){
        if (delegate != nil && [delegate respondsToSelector:@selector(handDidBeginAt:forUserId:)]) {
            NSDictionary *pointDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                                 [Point3D pointWithXnPoint:pPosition], nil] 
                                                                        forKeys:[NSArray arrayWithObjects:@"point", nil]];
            [delegate performSelector:@selector(handDidBeginAt:forUserId:) withObject:pointDictionary withObject:[NSString stringWithCString:strGesture encoding:NSUTF8StringEncoding]];
        }
    }
    
}


void XN_CALLBACK_TYPE Gesture_Process(xn::GestureGenerator &generator, const XnChar *strGesture, const XnPoint3D *pPosition, XnFloat fProgress, void *pCookie)
{
    
}

void XN_CALLBACK_TYPE Hand_Created(xn::HandsGenerator &generator, XnUserID userId, const XnPoint3D *pPosition, XnFloat fTime, void *pCookie)
{
    for (id delegate in delegates){
        if (delegate != nil && [delegate respondsToSelector:@selector(handDidBeginAt:forUserId:)]) {
            NSDictionary *pointDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                                 [Point3D pointWithXnPoint:pPosition], nil] 
                                                                        forKeys:[NSArray arrayWithObjects:@"point", nil]];
            [delegate performSelector:@selector(handDidBeginAt:forUserId:) withObject:pointDictionary withObject:[NSNumber numberWithInt:userId]];
        }
    }
}

void XN_CALLBACK_TYPE Hand_Update(xn::HandsGenerator &generator, XnUserID userId, const XnPoint3D *pPosition, XnFloat fTime, void *pCookie)
{

    for (id delegate in delegates){
        if (delegate != nil && [delegate respondsToSelector:@selector(handDidMoveAt:forUserId:)]) {
            NSDictionary *pointDictionary = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:
                                                                                 [Point3D pointWithXnPoint:pPosition], nil] 
                                                                        forKeys:[NSArray arrayWithObjects:@"point", nil]];
            [delegate performSelector:@selector(handDidMoveAt:forUserId:) withObject:pointDictionary withObject:[NSNumber numberWithInt:userId]];
        }
    }
}


void XN_CALLBACK_TYPE Hand_Lost(xn::HandsGenerator &generator, XnUserID userId, XnFloat fTime, void *pCookie)
{

    for (id delegate in delegates){
        if (delegate != nil && [delegate respondsToSelector:@selector(handDidStopForUserId:)]) {
            [delegate performSelector:@selector(handDidStopForUserId:) withObject:[NSNumber numberWithInt:userId]];
        }
    }
}


//TODO: implement Pose and calibration methods
void XN_CALLBACK_TYPE Pose_Detected(xn::PoseDetectionCapability &pose, const XnChar* strPose, XnUserID nId, void *pCookie)
{
    NSLog(@"Pose %s for user %d\n", strPose, nId);

    xnUserGenerator.GetPoseDetectionCap().StopPoseDetection(nId);
    xnUserGenerator.GetSkeletonCap().RequestCalibration(nId, true);
}


void XN_CALLBACK_TYPE Calibration_Start(xn::SkeletonCapability &capability, XnUserID nId, void *pCookie)
{
    NSLog(@"Starting calibration for user %d\n", nId);
}


void XN_CALLBACK_TYPE Calibration_End(xn::SkeletonCapability &capability, XnUserID nId, XnBool bSuccess, void *pCookie)
{
    if (bSuccess) {
        NSLog(@"User Calibrated\n");
        xnUserGenerator.GetSkeletonCap().StopTracking(nId);
    } else {
        NSLog(@"Failed to calibrate user %d\n", nId);
    }
}


#pragma mark - Gesture Detection Methods



-(void)startTrackingHandAtPosition:(Point3D*)_point
{
    xnHandGenerator.StartTracking([_point xnPoint3D]);
}

-(void)stopTrakcingHandWithUserId:(XnUserID)_userId
{
    xnHandGenerator.StopTracking(_userId);
}

-(void)startDetectingGesture:(GestureType)_gestureType
{
    xnGestureGenerator.AddGesture([[self stringForGestureType:_gestureType] cStringUsingEncoding:NSUTF8StringEncoding], NULL);
}

-(void)stopDetectingGesture:(GestureType)_gestureType
{
    xnGestureGenerator.RemoveGesture([[self stringForGestureType:_gestureType] cStringUsingEncoding:NSUTF8StringEncoding]);
}


-(NSString*)stringForGestureType:(GestureType)_gestureType
{
    NSString *gestureName;

    switch (_gestureType) {
        case GestureTypeClick:
            gestureName = @"Click";
            break;

        case GestureTypeWave:
            gestureName = @"Wave";
            break;

        case GestureTypeRaiseHand:
            gestureName = @"RaiseHand";
            break;

        case GestureTypeSwipeLeft:
            gestureName = @"SwipeLeft";
            break;
            
        case GestureTypeSwipeRight:
            gestureName = @"SwipeRight";
            break;
            
        default:
            gestureName = @"";
            break;
    }
    
    return gestureName;
}

-(const XnDepthPixel *)depthMap
{
    return xnDepthGenerator.GetDepthMap();
}
@end
