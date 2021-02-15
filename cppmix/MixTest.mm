//
//  MixTest.m
//  MixedLanguages
//
//  Created by Borna Noureddin on 2013-10-09.
//  Copyright (c) 2013 Borna Noureddin. All rights reserved.
//

#import "MixTest.h"
#include "CPlusPlus.h"

struct CPlusPlusClass
{
    CPlusPlus theObj;
};

@implementation MixTest

@synthesize val;
@synthesize useObjC;

- (id)init
{
    self = [super init];
    if (self) {
        useObjC = YES;
        val = 0;
        cPlusPlusObject = new CPlusPlusClass;
    }
    return self;
}

-(int) val
{
    return useObjC ? val : cPlusPlusObject->theObj.GetVal();
}

-(void)IncrementValue
{
    if (useObjC)
        val++;
    else
        cPlusPlusObject->theObj.IncrVal();
}


@end
