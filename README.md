# CuScrambler
This is a "Random Moves" scrambler with dynamic judgement, which makes the result more scrambled. This Scrambler only support 2x2x2 to 9x9x9 currently, you can improve it to 10x10x10 or even bigger.

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
    
    