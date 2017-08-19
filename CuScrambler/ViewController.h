//
//  ViewController.h
//  CuScrambler
//
//  Created by Mo Weipeng on 2017/8/19.
//  Copyright © 2017 cutimer.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Scrambler.h"

@interface ViewController : NSViewController

@property (weak) IBOutlet NSComboBoxCell *SelectingCubeTypeComboBoxCell;
@property (weak) IBOutlet NSTextField *GeneratingProcessLabel;
@property (unsafe_unretained) IBOutlet NSTextView *ResultTextView;
@property (weak) IBOutlet NSButton *GenerateButton;
@property (weak) IBOutlet NSTextField *MovesNumberTextField;

- (IBAction)TapGenerate:(id)sender;
- (IBAction)ChangeCubeType:(NSComboBoxCell *)sender;

@end

