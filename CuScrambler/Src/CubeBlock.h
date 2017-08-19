//
//  CubeBlock.h
//  MokScrambler
//
//  Created by Mo Weipeng on 2017/8/18.
//  Copyright © 2017 cutimer.com. All rights reserved.
//

#import <Foundation/Foundation.h>

// Pieces of a cube
@interface CubeBlock : NSObject
@property CTCubeColor U;
@property CTCubeColor D;
@property CTCubeColor L;
@property CTCubeColor R;
@property CTCubeColor F;
@property CTCubeColor B;
@property int ColorCount;  // Number of faces with color（A face without color means that it is not the face of the cube）

@end
