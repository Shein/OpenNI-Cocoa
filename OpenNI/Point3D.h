//
//  Point3D.h
//  OpenNI
//
//  Created by Daniel Shein on 2/5/12.
//  Copyright (c) 2012 LoFT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XnTypes.h>

@interface Point3D : NSObject{
    float x,y,z;
}

@property (nonatomic, assign) float x,y,z;


-(id)initWithX:(float)_x Y:(float)_y Z:(float)_z;
-(id)initWithXnPoint:(XnPoint3D*)_point;
+(Point3D*)pointWithXnPoint:(const XnPoint3D*)_point;
+(Point3D*)pointWithX:(float)_x Y:(float)_y Z:(float)_z;
-(const XnPoint3D)xnPoint3D;

@end
