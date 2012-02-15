//
//  OpenNITests.m
//  OpenNITests
//
//  Created by Daniel Shein on 1/24/12.
//  Copyright (c) 2012 LoFT. All rights reserved.
//

#import "OpenNITests.h"

@implementation OpenNITests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    openNI = [OpenNI instance];
    frameCount = 0;

    openNiInited = NO;
    initAttemptCount = 0;
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testOpenNiInit
{    
    if (openNI == NULL || openNI == nil)
    {
        STFail(@"Failed Getting instance of OpenNI");
    }
    
    [openNI addDelegate:self];
    [openNI initOpenNi];
    
    while (initAttemptCount < 10 && !initAttemptCount) {
        NSDate *fiveSecondsFromNow = [NSDate dateWithTimeIntervalSinceNow:60.0];
        [[NSRunLoop currentRunLoop] runUntilDate:fiveSecondsFromNow];
        initAttemptCount++;
    }
    
    STAssertTrue(openNiInited, @"Failed Initing OpenNi");
    
}


-(void)testStartFrameGeneration
{
    XnStatus rc = [openNI start];
    if (rc != XN_STATUS_OK) {
        STFail(@"Failed starting openNI");
    }
    
    NSDate *fiveSecondsFromNow = [NSDate dateWithTimeIntervalSinceNow:10.0];
    [[NSRunLoop currentRunLoop] runUntilDate:fiveSecondsFromNow];
    
    STAssertTrue(frameCount > 0, @"Failed Getting frames");
}


#pragma mark - OpenNI Delegate Methods

-(void)openNiInitCompleteWithStatus:(NSNumber *)_status andError:(NSError*)_error
{
    if ([_status isEqualToNumber:[NSNumber numberWithInt:0]]) {
        openNiInited = YES;
    } else {
        openNiInited = NO;
    }
}

-(void)frameReady
{   
    frameCount++;
    if (frameCount > 10) {
        [openNI stop];
    }
}

@end
