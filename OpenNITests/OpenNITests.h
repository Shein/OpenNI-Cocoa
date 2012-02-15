//
//  OpenNITests.h
//  OpenNITests
//
//  Created by Daniel Shein on 1/24/12.
//  Copyright (c) 2012 LoFT. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "OpenNI.h"

@interface OpenNITests : SenTestCase <OpenNIDelegate>
{
    OpenNI *openNI;
    //Test variables
    bool openNiInited;
    int initAttemptCount;
    int frameCount;
}

@end
