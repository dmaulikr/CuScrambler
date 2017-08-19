//
//  ViewController.m
//  CuScrambler
//
//  Created by Mo Weipeng on 2017/8/19.
//  Copyright © 2017 cutimer.com. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
int MOVES[] = {0,0,11,20,40,60,80,100,130,160};    // The required moves numbers of a scramble sequence of each type of cube

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (IBAction)TapGenerate:(id)sender {
    int cubeType = (int)self.SelectingCubeTypeComboBoxCell.indexOfSelectedItem + 2;
    MOVES[cubeType] = [self.MovesNumberTextField intValue];
    [self.GenerateButton setEnabled:NO];
    self.GeneratingProcessLabel.stringValue = @"Generating...";
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // generate scramble in new thread
        NSDate *startTime = [NSDate date];
        NSString *scramble = [Scrambler ScrambleExpress:cubeType Moves:MOVES[cubeType]];
        NSTimeInterval generatedTime = [[NSDate date] timeIntervalSinceDate:startTime];
        dispatch_async(dispatch_get_main_queue(), ^{
            // show in main thread
            [self.ResultTextView setString:scramble];
            [self.GenerateButton setEnabled:YES];
            self.GeneratingProcessLabel.stringValue = [NSString stringWithFormat:@"Generated in %.3f seconds", generatedTime];
        });
    });

}

- (IBAction)ChangeCubeType:(NSComboBoxCell *)sender {
    NSLog(@"change cube type: %@", sender.objectValueOfSelectedItem);
    int cubeType = (int)sender.indexOfSelectedItem + 2;
    int moves = MOVES[cubeType];
    self.MovesNumberTextField.stringValue = [NSString stringWithFormat:@"%d", moves];
}
@end
