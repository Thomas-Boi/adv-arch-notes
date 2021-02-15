//
//  MixTest.h
//  MixedLanguages
//
//  Created by Borna Noureddin on 2013-10-09.
//  Copyright (c) 2013 Borna Noureddin. All rights reserved.
//

#import <Foundation/Foundation.h>

struct CPlusPlusClass;

@interface MixTest : NSObject
{
    @private
    struct CPlusPlusClass *cPlusPlusObject;
}

@property (nonatomic) int val;
@property (nonatomic) BOOL useObjC;

-(void)IncrementValue;

@end
