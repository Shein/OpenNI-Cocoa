//
//  Point3D.m
//  OpenNI
//
//  Created by Daniel Shein on 2/5/12.
//  Copyright (c) 2012 LoFT. All rights reserved.
//

#import "Point3D.h"

@implementation Point3D
@synthesize x,y,z;


-(id)initWithX:(float)_x Y:(float)_y Z:(float)_z
{
    if (self = [super init])
    {
        self.x = _x;
        self.y = _y;
        self.z = _z;
    }
    
    return self;
}

-(id)initWithXnPoint:(XnPoint3D*)_point
{
    return [self initWithX:_point->X Y:_point->Y Z:_point->Z];
}


+(Point3D*)pointWithX:(float)_x Y:(float)_y Z:(float)_z
{
    return [[[Point3D alloc] initWithX:_x Y:_y Z:_z] autorelease];
}


+(Point3D*)pointWithXnPoint:(const XnPoint3D*)_point
{    
    return [[[Point3D alloc] initWithXnPoint:_point] autorelease];
}


-(const XnPoint3D)xnPoint3D
{
    XnPoint3D point;
    point.X = x;
    point.Y = y;
    point.Z = z;
    
    return point;
}

-(NSString*)description
{
    return [NSString stringWithFormat:@"( %f, %f, %f )", x, y, z];
}

@end
