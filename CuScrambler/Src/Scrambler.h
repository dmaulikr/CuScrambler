//
//  Scrambler.h
//  MokScrambler
//
//  Created by Mo Weipeng on 2017/8/18.
//  Copyright © 2017 cutimer.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CubeBlock.h"

@interface Scrambler : NSObject
+(NSString *)ScrambleExpress:(int)cubeSize Moves:(int)movesNumber;
@end
