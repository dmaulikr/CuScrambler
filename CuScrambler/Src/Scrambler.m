//
//  Scrambler.m
//  MokScrambler
//
//  Created by Mo Weipeng on 2017/8/18.
//  Copyright © 2017 cutimer.com. All rights reserved.
//

#import "Scrambler.h"

@implementation Scrambler
int DEFAULT_MOVES_NUMBER[] = {0,0,11,20,40,60,80,100,130,160};    // The required moves numbers of a scramble sequence of each type of cube
+(NSString *)ScrambleExpress:(int)cubeSize Moves:(int)movesNumber{
    /*
     Definitions:
     Rotating Direction: A single move of a scramble sequence. U', U2, U are 3 different directions.
     Rotating Set: Base on moving layers of a Rotating Direction. U', U2, U are in the same Rotating Set, Uw', Uw2, Uw are in the same Rotating Set, but U' and Uw' are not.
     Rotating Set Group: Base on dimension of a Rotating Set. U', Uw, 3Uw2 are in the same Rotating Set Group, but U' and L are not.
     Scramble Score: The score to judge the scramble status of a cube. 
                     For 2 neighbor pieces of a cube, if they are both corner or edge pieces and they were neighbor when the cube was solved, add 4 point to the total score;
                                                      if 1 of them is center piece (which means not corner or edge) and they were neighbor when the cube was solved, add 1 point to the total score.
                     Why: The best scrambled effect after many times of experiments.
                     The less the score, the better the scramble effect is.
     */
    
    /* Extra Requirements:
     1. Rotating Directions in the same Rotating Set cannot be selected in continuous twice. E.g. U U2 is not allowed in a scramble sequence.
     2. Rotating Directions in the same Rotating Set Group cannot be selected in continuous three times. E.g. U Uw U' is not allowed in a scramble sequence.
     */
    
    /* Algorithm:
     1. Get the total moves of the result scramble sequence by cube type.
     2. Before selecting the Rotating Direction of each move, calculate how the Scramble Score will be after applying every selectable Rotating Direction.
        Optimization: To reduce the calculating time, only get random several (9 here, you can change RANDOM_JUDGING_NUM) of selectable Rotating Directions to calculate.
                      The scramble result will be influenced, but still good enough.
     3. Get a random one of the best several (1/3 of above, you can change it) of Rotating Directions selected above.
     4. Remember each selected Rotating Direction and generate the result of scramble sequence.
     */
    
    /* How to describe a cube:
     Simulate a 3-dimensional array of CubeBlock. A CubeBlock is a single piece of the cube, and contains 6 faces: U, D, L, R, F, B. 
     Not all of 6 faces are used. A corner piece only uses 3 faces, an edge piece only uses 2 faces, and a center piece only uses 1 face.
     
     Each of 6 faces has color value. The color values of unused faces are 0. Obviously, there will be many redundant data for easy description and calculation.
     
     As I didn't know a good description of a 3-dimensional array in Objective-C, I describe it with NSDictionary instead. 
     Before set or get value, we need to calculate the key by (x,y,z) axes, and get the CubeBlock from the NSDictionary.
     
     Convention here: X is from L to R, Y is from U to D, and Z is from B to F
     */
    
    /* About rotation:
     For easier implementation and calculate when implementing (and copy the code to reduce the manual coordinate calculation ^_^), I decided:
     U,Uw,F,Fw,L,Lw...: Base on clockwise. Counterclockwise means 3 times of clockwise, and turn 180 degree means twice of clockwise;
     D,Dw,B,Bw,R,Rw...: Base on counterclockwise. Clockwise means 3 times of counterclockwise, and turn 180 degree means twice of counterclockwise.
     */
    
    if (cubeSize < 2 || cubeSize > 9) {
        return nil;
    }
    
    NSDate *startTime = [NSDate date];
    
    const int RANDOM_JUDGING_NUM = 9;           // the number of selected Rotating Directions for calculate
    int steps = movesNumber > 0 ? movesNumber : DEFAULT_MOVES_NUMBER[cubeSize];
    CTCubeRotateDirection last = -1;      // last Rotating Direction
    CTCubeRotateDirection last2 = -1;     // last last Rotating Direction
    NSString *result = @"";
    
    NSMutableDictionary<NSNumber*,CubeBlock*> *cube = [self NewCubeOfType:cubeSize];        // Create a cube
    for (int i = 0; i < steps; i++) {
        NSLog(@"Scramble step: %d",i);
        int currentScrameblePoint = [self CalculateScramblePointForCube:cube cubeType:cubeSize];  // calculating scramble point here costs time too. comment out it before release
        NSLog(@"Current scramble point: %d", currentScrameblePoint);
        
        NSMutableArray<NSNumber*>* validDirections = [self GetValidDirectionsForCubeType:cubeSize last:last last2:last2];   // The selectable Rotating Directions of current move
        //        NSLog(@"valid directions: %@", validDirections);
        NSMutableArray<NSNumber*>* randomDirections = [self GetRandomDirections:validDirections num:RANDOM_JUDGING_NUM];    // To reduce calculation, select random Rotating Directions
        //        NSLog(@"random directions: %@", randomDirections);
        
        NSMutableDictionary<NSNumber*,NSNumber*>* directionPoints = [NSMutableDictionary dictionary];                       // The Scramble Score after applying each Rotating Directions
        for (NSNumber* directionNumber in randomDirections) {
            CTCubeRotateDirection direction = [directionNumber intValue];
            int point = [self JudgeDirectionPointForCube:cube cubeType:cubeSize toDirection:direction];
            [directionPoints setObject:[NSNumber numberWithInt:point] forKey:directionNumber];
        }
        //        NSLog(@"direction points: %@", directionPoints);
        // Sorted by Scramble Scores ascending
        NSArray<NSNumber*> *sortedDirection = [directionPoints keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber* point1, NSNumber* point2){
            return [point1 compare:point2];
        }];
        
        NSMutableArray<NSNumber *> *bestDirections = [NSMutableArray array];       // The Rotating Directioin array of the best scramble effect
        // Put the best 1/3 of selectable Rotating Directions to the Selecting Library, and then select a random one from the Selecting Library.
        // If there are more then 1 Rotating Directions with the same Scramble Score in the place of 1/3, put all of them into the Selecting Library.
        NSNumber *base = [sortedDirection objectAtIndex:(sortedDirection.count - 1)/3 + 1];
        NSNumber *basePoint = [directionPoints objectForKey:base];
        for (int j = 0; j < sortedDirection.count; j++) {
            NSNumber* directionNumber = [sortedDirection objectAtIndex:j];
            NSNumber* directionPoint = [directionPoints objectForKey:directionNumber];
            if ([directionPoint intValue] <= [basePoint intValue]) {
                [bestDirections addObject:directionNumber];
            }
        }
        //        NSLog(@"best directions: %@", bestDirections);
        
        int randomSelected = [self randomLessThan:(int)bestDirections.count];
        NSNumber *selectedDirectionNumber = [bestDirections objectAtIndex:randomSelected];
        CTCubeRotateDirection selectedDirection = [selectedDirectionNumber intValue];
        
        NSString* directionString = [self GetDirectionString:selectedDirection];
        //        NSLog(@"selected direction: %d - %@", (int)selectedDirection, directionString);
        last2 = last;
        last = selectedDirection;
        // Rotate the cube by the selected Rotating Direction
        [self RotateForCube:cube cubeType:cubeSize toDirection:selectedDirection];
        result = [result stringByAppendingString:directionString];
        //        NSLog(@"current step: %d scramble: %@ ", i, result);
    }
    
    NSTimeInterval generatedTime = [[NSDate date] timeIntervalSinceDate:startTime];
    NSLog(@"time of generating scramble: %.3f", generatedTime);
    return result;
}

+(NSNumber*)CalculateKeyByAxesX:(int)x Y:(int)y Z:(int)z{
    // The method to generate the key: 100x+10y+z. You can change it to 121x+11y+z if you want it to support 10x10x10, and so on.
    return [NSNumber numberWithInt: (x * 100 + y * 10 + z)];
}

+(NSString*)GetDirectionString:(CTCubeRotateDirection)direction{
    NSArray<NSString*> *directionStrings = @[@"U ",@"F ",@"L ",@"D ",@"B ",@"R ",
                                             @"Uw ",@"Fw ",@"Lw ",@"Dw ",@"Bw ",@"Rw ",
                                             @"3Uw ",@"3Fw ",@"3Lw ",@"3Dw ",@"3Bw ",@"3Rw ",
                                             @"4Uw ",@"4Fw ",@"4Lw ",@"4Dw ",@"4Bw ",@"4Rw ",
                                             @"U' ",@"F' ",@"L' ",@"D' ",@"B' ",@"R' ",
                                             @"Uw' ",@"Fw' ",@"Lw' ",@"Dw' ",@"Bw' ",@"Rw' ",
                                             @"3Uw' ",@"3Fw' ",@"3Lw' ",@"3Dw' ",@"3Bw' ",@"3Rw' ",
                                             @"4Uw' ",@"4Fw' ",@"4Lw' ",@"4Dw' ",@"4Bw' ",@"4Rw' ",
                                             @"U2 ",@"F2 ",@"L2 ",@"D2 ",@"B2 ",@"R2 ",
                                             @"Uw2 ",@"Fw2 ",@"Lw2 ",@"Dw2 ",@"Bw2 ",@"Rw2 ",
                                             @"3Uw2 ",@"3Fw2 ",@"3Lw2 ",@"3Dw2 ",@"3Bw2 ",@"3Rw2 ",
                                             @"4Uw2 ",@"4Fw2 ",@"4Lw2 ",@"4Dw2 ",@"4Bw2 ",@"4Rw2 "];
    return [directionStrings objectAtIndex:direction];
}

+(NSMutableArray<NSNumber *>*)GetRandomDirections:(NSMutableArray<NSNumber *>*)directions num:(int)num{
    if (num > directions.count) {
        return nil;
    }
    NSMutableArray<NSNumber *>* tempDirections = [NSMutableArray array];
    for (NSNumber *dir in directions) {
        [tempDirections addObject:dir];
    }
    NSMutableArray<NSNumber *>* result = [NSMutableArray array];
    for (int i = 0; i < num; i++) {
        int randomNumber = [self randomLessThan:tempDirections.count];
        NSNumber *dir = [tempDirections objectAtIndex:randomNumber];
        [result addObject:dir];
        [tempDirections removeObjectAtIndex:randomNumber];
    }
    return result;
}

+(CTCubeColor)GetFaceColorOfCube:(NSMutableDictionary<NSNumber*,CubeBlock*>*)cubeDictionary onFace:(CTCubeFace)face ofAxesX:(int)x Y:(int)y Z:(int)z{
    CubeBlock *block = [self GetBlockOfCube:cubeDictionary ofAxesX:x Y:y Z:z];
    switch (face) {
        case CTFaceUp: return block.U;
        case CTFaceDown: return block.D;
        case CTFaceLeft: return block.L;
        case CTFaceRight: return block.R;
        case CTFaceFront: return block.F;
        case CTFaceBack: return block.B;
            
        default:
            break;
    }
    return CTColorNone;
}

+(void)SetFaceColor:(CTCubeColor)color toCube:(NSMutableDictionary<NSNumber*,CubeBlock*>*)cubeDictionary onFace:(CTCubeFace)face ofAxesX:(int)x Y:(int)y Z:(int)z isNew:(bool)isNew{
    NSNumber *key = [self CalculateKeyByAxesX:x Y:y Z:z];
    CubeBlock *block = [self GetBlockOfCube:cubeDictionary ofAxesX:x Y:y Z:z];
    switch (face) {
        case CTFaceUp: block.U = color; break;
        case CTFaceDown: block.D = color; break;
        case CTFaceLeft: block.L = color; break;
        case CTFaceRight: block.R = color; break;
        case CTFaceFront: block.F = color; break;
        case CTFaceBack: block.B = color; break;
            
        default:
            break;
    }
    if (isNew) {
        block.ColorCount++;
    }
    
    [cubeDictionary setObject:block forKey:key];
    
}

+(CubeBlock *)GetBlockOfCube:(NSMutableDictionary<NSNumber*,CubeBlock*>*)cubeDictionary ofAxesX:(int)x Y:(int)y Z:(int)z{
    NSNumber *key = [self CalculateKeyByAxesX:x Y:y Z:z];
    return [cubeDictionary objectForKey:key];
}

+(NSMutableDictionary<NSNumber*,CubeBlock*> *)NewCubeOfType:(int)cubeType{
    NSMutableDictionary<NSNumber*,CubeBlock*> *cubeDictionary = [NSMutableDictionary dictionary];
    // Create pieces of the cube
    for (int i = 0; i < cubeType; i++) {
        for (int j = 0; j < cubeType; j++) {
            for (int k = 0; k < cubeType; k++) {
                NSNumber *key = [self CalculateKeyByAxesX:i Y:j Z:k];
                CubeBlock *block = [[CubeBlock alloc] init];
                block.ColorCount = 0;
                block.U = CTColorNone;
                block.D = CTColorNone;
                block.L = CTColorNone;
                block.R = CTColorNone;
                block.F = CTColorNone;
                block.B = CTColorNone;
                [cubeDictionary setObject:block forKey:key];
            }
        }
    }
    // color those pieces
    for (int i = 0; i < cubeType; i++) {
        for (int j = 0; j < cubeType; j++) {
            [self SetFaceColor:CTColorWhite toCube:cubeDictionary onFace:CTFaceUp ofAxesX:i Y:0 Z:j isNew:YES];
            [self SetFaceColor:CTColorYellow toCube:cubeDictionary onFace:CTFaceDown ofAxesX:i Y:cubeType-1 Z:j isNew:YES];
            [self SetFaceColor:CTColorOrange toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:i Z:j isNew:YES];
            [self SetFaceColor:CTColorRed toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:i Z:j isNew:YES];
            [self SetFaceColor:CTColorGreen toCube:cubeDictionary onFace:CTFaceFront ofAxesX:i Y:j Z:cubeType-1 isNew:YES];
            [self SetFaceColor:CTColorBlue toCube:cubeDictionary onFace:CTFaceBack ofAxesX:i Y:j Z:0 isNew:YES];
        }
    }
    return cubeDictionary;
}

// (U)
+(void)RotateUpForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType{
    // Rotate the color of the face
    for (int i = 0; i < (cubeType+1)/2; i++) {
        for (int j = 0; j < cubeType/2; j++) {
            CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceUp ofAxesX:i Y:0 Z:j];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceUp ofAxesX:j Y:0 Z:cubeType-1-i] toCube:cubeDictionary onFace:CTFaceUp ofAxesX:i Y:0 Z:j isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1-i Y:0 Z:cubeType-1-j] toCube:cubeDictionary onFace:CTFaceUp ofAxesX:j Y:0 Z:cubeType-1-i isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1-j Y:0 Z:i] toCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1-i Y:0 Z:cubeType-1-j isNew:NO];
            [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1-j Y:0 Z:i isNew:NO];
        }
    }
    // Rotate colors of sides
    for (int i = 0; i < cubeType; i++) {
        CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:0 Z:i];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceFront ofAxesX:i Y:0 Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:0 Z:i isNew:NO];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:0 Z:cubeType-1-i] toCube:cubeDictionary onFace:CTFaceFront ofAxesX:i Y:0 Z:cubeType-1 isNew:NO];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1-i Y:0 Z:0] toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:0 Z:cubeType-1-i isNew:NO];
        [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1-i Y:0 Z:0 isNew:NO];
    }
}
// (nUw) (rotate the top layer first, and rotate the others)
+(void)RotateUpWForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType layersNumber:(int)layersNumber{
    [self RotateUpForCube:cubeDictionary cubeType:cubeType];
    for (int n = 1; n < layersNumber; n++) {
        for (int i = 0; i < cubeType; i++) {
            CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:n Z:i];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceFront ofAxesX:i Y:n Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:n Z:i isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:n Z:cubeType-1-i] toCube:cubeDictionary onFace:CTFaceFront ofAxesX:i Y:n Z:cubeType-1 isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1-i Y:n Z:0] toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:n Z:cubeType-1-i isNew:NO];
            [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1-i Y:n Z:0 isNew:NO];
        }
    }
}

// (D')
+(void)RotateDownReverseForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType{
    for (int i = 0; i < (cubeType+1)/2; i++) {
        for (int j = 0; j < cubeType/2; j++) {
            CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceDown ofAxesX:i Y:cubeType-1 Z:j];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceDown ofAxesX:j Y:cubeType-1 Z:cubeType-1-i] toCube:cubeDictionary onFace:CTFaceDown ofAxesX:i Y:cubeType-1 Z:j isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceDown ofAxesX:cubeType-1-i Y:cubeType-1 Z:cubeType-1-j] toCube:cubeDictionary onFace:CTFaceDown ofAxesX:j Y:cubeType-1 Z:cubeType-1-i isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceDown ofAxesX:cubeType-1-j Y:cubeType-1 Z:i] toCube:cubeDictionary onFace:CTFaceDown ofAxesX:cubeType-1-i Y:cubeType-1 Z:cubeType-1-j isNew:NO];
            [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceDown ofAxesX:cubeType-1-j Y:cubeType-1 Z:i isNew:NO];
        }
    }
    for (int i = 0; i < cubeType; i++) {
        CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:cubeType-1 Z:i];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceFront ofAxesX:i Y:cubeType-1 Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:cubeType-1 Z:i isNew:NO];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1 Z:cubeType-1-i] toCube:cubeDictionary onFace:CTFaceFront ofAxesX:i Y:cubeType-1 Z:cubeType-1 isNew:NO];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1-i Y:cubeType-1 Z:0] toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1 Z:cubeType-1-i isNew:NO];
        [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1-i Y:cubeType-1 Z:0 isNew:NO];
    }
}
// (nDw')
+(void)RotateDownWReverseForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType layersNumber:(int)layersNumber{
    [self RotateDownReverseForCube:cubeDictionary cubeType:cubeType];
    for (int n = cubeType - 2; n >= cubeType - layersNumber; n--) {
        for (int i = 0; i < cubeType; i++) {
            CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:n Z:i];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceFront ofAxesX:i Y:n Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:n Z:i isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:n Z:cubeType-1-i] toCube:cubeDictionary onFace:CTFaceFront ofAxesX:i Y:n Z:cubeType-1 isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1-i Y:n Z:0] toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:n Z:cubeType-1-i isNew:NO];
            [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1-i Y:n Z:0 isNew:NO];
        }
    }
}

// (F)
+(void)RotateFrontForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType{
    for (int i = 0; i < (cubeType+1)/2; i++) {
        for (int j = 0; j < cubeType/2; j++) {
            CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceFront ofAxesX:i Y:j Z:cubeType-1];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceFront ofAxesX:j Y:cubeType-1-i Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceFront ofAxesX:i Y:j Z:cubeType-1 isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceFront ofAxesX:cubeType-1-i Y:cubeType-1-j Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceFront ofAxesX:j Y:cubeType-1-i Z:cubeType-1 isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceFront ofAxesX:cubeType-1-j Y:i Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceFront ofAxesX:cubeType-1-i Y:cubeType-1-j Z:cubeType-1 isNew:NO];
            [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceFront ofAxesX:cubeType-1-j Y:i Z:cubeType-1 isNew:NO];
        }
    }
    for (int i = 0; i < cubeType; i++) {
        CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:i Z:cubeType-1];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceDown ofAxesX:i Y:cubeType-1 Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:i Z:cubeType-1 isNew:NO];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1-i Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceDown ofAxesX:i Y:cubeType-1 Z:cubeType-1 isNew:NO];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1-i Y:0 Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1-i Z:cubeType-1 isNew:NO];
        [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1-i Y:0 Z:cubeType-1 isNew:NO];
    }
}
// (nFw)
+(void)RotateFrontWForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType layersNumber:(int)layersNumber{
    [self RotateFrontForCube:cubeDictionary cubeType:cubeType];
    for (int n = cubeType - 2; n >= cubeType - layersNumber; n--) {
        for (int i = 0; i < cubeType; i++) {
            CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:i Z:n];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceDown ofAxesX:i Y:cubeType-1 Z:n] toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:i Z:n isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1-i Z:n] toCube:cubeDictionary onFace:CTFaceDown ofAxesX:i Y:cubeType-1 Z:n isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1-i Y:0 Z:n] toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1-i Z:n isNew:NO];
            [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1-i Y:0 Z:n isNew:NO];
        }
    }
}

// (B')
+(void)RotateBackReverseForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType{
    for (int i = 0; i < (cubeType+1)/2; i++) {
        for (int j = 0; j < cubeType/2; j++) {
            CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceBack ofAxesX:i Y:j Z:0];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceBack ofAxesX:j Y:cubeType-1-i Z:0] toCube:cubeDictionary onFace:CTFaceBack ofAxesX:i Y:j Z:0 isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1-i Y:cubeType-1-j Z:0] toCube:cubeDictionary onFace:CTFaceBack ofAxesX:j Y:cubeType-1-i Z:0 isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1-j Y:i Z:0] toCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1-i Y:cubeType-1-j Z:0 isNew:NO];
            [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1-j Y:i Z:0 isNew:NO];
        }
    }
    for (int i = 0; i < cubeType; i++) {
        CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:i Z:0];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceDown ofAxesX:i Y:cubeType-1 Z:0] toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:i Z:0 isNew:NO];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1-i Z:0] toCube:cubeDictionary onFace:CTFaceDown ofAxesX:i Y:cubeType-1 Z:0 isNew:NO];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1-i Y:0 Z:0] toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1-i Z:0 isNew:NO];
        [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1-i Y:0 Z:0 isNew:NO];
    }
}
// (nBw')
+(void)RotateBackWReverseForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType layersNumber:(int)layersNumber{
    [self RotateBackReverseForCube:cubeDictionary cubeType:cubeType];
    for (int n = 1; n < layersNumber; n++) {
        for (int i = 0; i < cubeType; i++) {
            CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:i Z:n];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceDown ofAxesX:i Y:cubeType-1 Z:n] toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:i Z:n isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1-i Z:n] toCube:cubeDictionary onFace:CTFaceDown ofAxesX:i Y:cubeType-1 Z:n isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1-i Y:0 Z:n] toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1-i Z:n isNew:NO];
            [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1-i Y:0 Z:n isNew:NO];
        }
    }
}

// (L)
+(void)RotateLeftForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType{
    for (int i = 0; i < (cubeType+1)/2; i++) {
        for (int j = 0; j < cubeType/2; j++) {
            CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:j Z:i];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:cubeType-1-i Z:j] toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:j Z:i isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:cubeType-1-j Z:cubeType-1-i] toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:cubeType-1-i Z:j isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:i Z:cubeType-1-j] toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:cubeType-1-j Z:cubeType-1-i isNew:NO];
            [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceLeft ofAxesX:0 Y:i Z:cubeType-1-j isNew:NO];
        }
    }
    for (int i = 0; i < cubeType; i++) {
        CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceBack ofAxesX:0 Y:i Z:0];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceDown ofAxesX:0 Y:cubeType-1 Z:i] toCube:cubeDictionary onFace:CTFaceBack ofAxesX:0 Y:i Z:0 isNew:NO];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceFront ofAxesX:0 Y:cubeType-1-i Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceDown ofAxesX:0 Y:cubeType-1 Z:i isNew:NO];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceUp ofAxesX:0 Y:0 Z:cubeType-1-i] toCube:cubeDictionary onFace:CTFaceFront ofAxesX:0 Y:cubeType-1-i Z:cubeType-1 isNew:NO];
        [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceUp ofAxesX:0 Y:0 Z:cubeType-1-i isNew:NO];
    }
}
// (nLw)
+(void)RotateLeftWForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType layersNumber:(int)layersNumber{
    [self RotateLeftForCube:cubeDictionary cubeType:cubeType];
    for (int n = 1; n < layersNumber; n++) {
        for (int i = 0; i < cubeType; i++) {
            CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceBack ofAxesX:n Y:i Z:0];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceDown ofAxesX:n Y:cubeType-1 Z:i] toCube:cubeDictionary onFace:CTFaceBack ofAxesX:n Y:i Z:0 isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceFront ofAxesX:n Y:cubeType-1-i Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceDown ofAxesX:n Y:cubeType-1 Z:i isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceUp ofAxesX:n Y:0 Z:cubeType-1-i] toCube:cubeDictionary onFace:CTFaceFront ofAxesX:n Y:cubeType-1-i Z:cubeType-1 isNew:NO];
            [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceUp ofAxesX:n Y:0 Z:cubeType-1-i isNew:NO];
        }
    }
}

// (R')
+(void)RotateRightReverseForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType{
    for (int i = 0; i < (cubeType+1)/2; i++) {
        for (int j = 0; j < cubeType/2; j++) {
            CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:j Z:i];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1-i Z:j] toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:j Z:i isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1-j Z:cubeType-1-i] toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1-i Z:j isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:i Z:cubeType-1-j] toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:cubeType-1-j Z:cubeType-1-i isNew:NO];
            [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceRight ofAxesX:cubeType-1 Y:i Z:cubeType-1-j isNew:NO];
        }
    }
    for (int i = 0; i < cubeType; i++) {
        CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1 Y:i Z:0];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceDown ofAxesX:cubeType-1 Y:cubeType-1 Z:i] toCube:cubeDictionary onFace:CTFaceBack ofAxesX:cubeType-1 Y:i Z:0 isNew:NO];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceFront ofAxesX:cubeType-1 Y:cubeType-1-i Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceDown ofAxesX:cubeType-1 Y:cubeType-1 Z:i isNew:NO];
        [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1 Y:0 Z:cubeType-1-i] toCube:cubeDictionary onFace:CTFaceFront ofAxesX:cubeType-1 Y:cubeType-1-i Z:cubeType-1 isNew:NO];
        [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceUp ofAxesX:cubeType-1 Y:0 Z:cubeType-1-i isNew:NO];
    }
}
// (nRw')
+(void)RotateRightWReverseForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType layersNumber:(int)layersNumber{
    [self RotateRightReverseForCube:cubeDictionary cubeType:cubeType];
    for (int n = cubeType - 2; n >= cubeType - layersNumber; n--) {
        for (int i = 0; i < cubeType; i++) {
            CTCubeColor tempColor = [self GetFaceColorOfCube:cubeDictionary onFace:CTFaceBack ofAxesX:n Y:i Z:0];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceDown ofAxesX:n Y:cubeType-1 Z:i] toCube:cubeDictionary onFace:CTFaceBack ofAxesX:n Y:i Z:0 isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceFront ofAxesX:n Y:cubeType-1-i Z:cubeType-1] toCube:cubeDictionary onFace:CTFaceDown ofAxesX:n Y:cubeType-1 Z:i isNew:NO];
            [self SetFaceColor:[self GetFaceColorOfCube:cubeDictionary onFace:CTFaceUp ofAxesX:n Y:0 Z:cubeType-1-i] toCube:cubeDictionary onFace:CTFaceFront ofAxesX:n Y:cubeType-1-i Z:cubeType-1 isNew:NO];
            [self SetFaceColor:tempColor toCube:cubeDictionary onFace:CTFaceUp ofAxesX:n Y:0 Z:cubeType-1-i isNew:NO];
        }
    }
}

+(int)JudgeDirectionPointForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType toDirection:(CTCubeRotateDirection)direction{
    // clone a new cube for rotating and calculating
    NSMutableDictionary<NSNumber*,CubeBlock*> *tempDictionary = [NSMutableDictionary dictionary];
    for (NSNumber* key in cubeDictionary.allKeys) {
        CubeBlock* cubeBlock = [cubeDictionary objectForKey:key];
        CubeBlock* newBlock = [[CubeBlock alloc] init];
        newBlock.U = cubeBlock.U;
        newBlock.D = cubeBlock.D;
        newBlock.F = cubeBlock.F;
        newBlock.B = cubeBlock.B;
        newBlock.R = cubeBlock.R;
        newBlock.L = cubeBlock.L;
        newBlock.ColorCount = cubeBlock.ColorCount;
        [tempDictionary setObject:newBlock forKey:key];
    }
    // rotate the new cube
    [self RotateForCube:tempDictionary cubeType:cubeType toDirection:direction];
    // calculate the score
    return [self CalculateScramblePointForCube:tempDictionary cubeType:cubeType];
}

// TODO: by redefinition of the rotating directions, these switch cases number could be reduced to 6; but then rotate methods (D,B,R) have to be re-implement, and I am too lazy to do that.
+(void)RotateForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType toDirection:(CTCubeRotateDirection)direction{
    int rotateLayersNumber = direction % 24 / 6 + 1;
    switch (direction - 6*(rotateLayersNumber-1)) {
        case 0:  // U,Uw,3Uw,4Uw
            [self RotateUpWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 24:  // U',Uw',3Uw',4Uw', clockwise 3 times means counterclockwise
            [self RotateUpWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateUpWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateUpWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 48:  // U2,Uw2,3Uw2,4Uw2
            [self RotateUpWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateUpWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 3:   // D,Dw,3Dw,4Dw counterclockwise 3 timers means clockwise
            [self RotateDownWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateDownWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateDownWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 27:  // D',Dw',3Dw',4Dw'
            [self RotateDownWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 51:  // D2,Dw2,3Dw2,4Dw2
            [self RotateDownWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateDownWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 1:   // F,Fw,3Fw,4Fw
            [self RotateFrontWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 25:  // F',Fw',3Fw',4Fw'
            [self RotateFrontWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateFrontWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateFrontWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 49:  // F2,Fw2,3Fw2,4Fw2
            [self RotateFrontWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateFrontWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 4:   // B,Bw,3Bw,4Bw
            [self RotateBackWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateBackWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateBackWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 28:  // B',Bw',3Bw',4Bw'
            [self RotateBackWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 52:  // B2,Bw2,3Bw2,4Bw2
            [self RotateBackWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateBackWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 2:   // L,Lw,3Lw,4Lw
            [self RotateLeftWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 26:  // L',Lw',3Lw',4Lw'
            [self RotateLeftWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateLeftWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateLeftWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 50:  // L2,Lw2,3Lw2,4Lw2
            [self RotateLeftWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateLeftWForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 5:   // R,Rw,3Rw,4Rw
            [self RotateRightWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateRightWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateRightWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 29:  // R',Rw',3Rw',4Rw'
            [self RotateRightWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        case 53:  // R2,Rw2,3Rw2,4Rw2
            [self RotateRightWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            [self RotateRightWReverseForCube:cubeDictionary cubeType:cubeType layersNumber:rotateLayersNumber];
            break;
        default:
            break;
    }
}

+(NSMutableArray<NSNumber*>*) GetValidDirectionsForCubeType:(int)cubeType last:(int)last last2:(int)last2{
    if (cubeType < 2) {
        return nil;
    }
    NSMutableArray<NSNumber*>* result = [NSMutableArray array];
    for (int i = 0; i < 72; i++) {
        if (cubeType < 4 && i % 24 > 5) {
            // 2x2x2 & 3x3x3, there are no nXw Rotating Directions. Similarly below
            continue;
        }
        if (cubeType < 6 && i % 24 > 11){
            // 4x4x4 & 5x5x5
            continue;
        }
        if(cubeType < 8 && i % 24 > 17){
            // 6x6x6 & 7x7x7
            continue;
        }
        if (last >= 0 && last % 24 == i % 24) {
            //　Rotating Directions in the same Rotating Set cannot be selected in continous twice.
            continue;
        }
        if (last >= 0 && last2 >= 0 && last % 3 == last2 % 3 && last % 3 == i % 3) {
            // Rotating Directions in the same Rotating Set Group cannot be selected in continous three times.
            continue;
        }
        [result addObject:[NSNumber numberWithInt:i]];
    }
    return result;
}

+(int)CalculateScramblePointForCube:(NSMutableDictionary<NSNumber*,CubeBlock*> *)cubeDictionary cubeType:(int)cubeType{
    int result = 0;
    for (int i = 0; i < cubeType; i++) {
        for (int j = 0; j < cubeType; j++) {
            for (int k = 0; k < cubeType; k++) {
                if (i < cubeType - 1) {
                    result += [self CheckSamePointBetweenCube1:[self GetBlockOfCube:cubeDictionary ofAxesX:i Y:j Z:k] andCube2:[self GetBlockOfCube:cubeDictionary ofAxesX:i+1 Y:j Z:k]];
                }
                if (j < cubeType - 1) {
                    result += [self CheckSamePointBetweenCube1:[self GetBlockOfCube:cubeDictionary ofAxesX:i Y:j Z:k] andCube2:[self GetBlockOfCube:cubeDictionary ofAxesX:i Y:j+1 Z:k]];
                }
                if (k < cubeType - 1) {
                    result += [self CheckSamePointBetweenCube1:[self GetBlockOfCube:cubeDictionary ofAxesX:i Y:j Z:k] andCube2:[self GetBlockOfCube:cubeDictionary ofAxesX:i Y:j Z:k+1]];
                }
            }
        }
    }
    
    return result;
}

+(int)CheckSamePointBetweenCube1:(CubeBlock*)cube1 andCube2:(CubeBlock*)cube2{
    if (cube1.ColorCount == 0 || cube2.ColorCount == 0) {
        return 0;
    }
    int same = 0;
    if (cube1.U != CTColorNone && cube1.U == cube2.U) same++;
    if (cube1.D != CTColorNone && cube1.D == cube2.D) same++;
    if (cube1.F != CTColorNone && cube1.F == cube2.F) same++;
    if (cube1.B != CTColorNone && cube1.B == cube2.B) same++;
    if (cube1.L != CTColorNone && cube1.L == cube2.L) same++;
    if (cube1.R != CTColorNone && cube1.R == cube2.R) same++;
    
    if (cube1.ColorCount >= 2 && cube2.ColorCount >= 2) {      // Both are corner or edge pieces
        if (same < 2) {
            return 0;
        } else {
            return 4;
        }
    }
    if (cube1.ColorCount == 1 || cube2.ColorCount == 1) {      // At lease 1 is center piece
        if (same < 1) {
            return 0;
        } else {
            return 1;
        }
    }
    
    return 0;
}

+(int)randomLessThan:(unsigned long)max{
    return arc4random()%max;
}

@end
