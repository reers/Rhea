//
//  GAIATypes.h
//  Rhea_Example
//
//  Created by phoenix on 2024/8/13.
//  Copyright © 2024 Reer. All rights reserved.
//

#ifndef GAIATypes_h
#define GAIATypes_h

#include <stdbool.h>
#include <stdint.h>

typedef enum {
    GAIATypeFunction = 1,
    GAIATypeObjCMethod = 2,
    GAIATypeFunctionInfo = 3
} GAIAType;

typedef struct {
    const void* function;
    const char* fileName;
    int32_t line;
} GAIAFunctionInfo;

typedef struct {
    GAIAType type;
    bool repeatable;
    const char* key;
    const void* value;
} GAIAData;

#endif /* GAIATypes_h */
