//
//  CPlusPlus.h
//  MixedLanguages
//
//  Created by Borna Noureddin on 2013-10-09.
//  Copyright (c) 2013 Borna Noureddin. All rights reserved.
//

#ifndef __MixedLanguages__CPlusPlus__
#define __MixedLanguages__CPlusPlus__

#include <iostream>

class CPlusPlus
{

public:
    CPlusPlus() { val = 0; };
    ~CPlusPlus() {};
    
    int GetVal();
    void SetVal(int newVal);
    void IncrVal(int incr = 1);
    
private:
    int val;
    
};

#endif /* defined(__MixedLanguages__CPlusPlus__) */
