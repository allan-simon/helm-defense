# helm-defense
simple game in love2d 

## Bibliography

### Colission avoidance

  * https://gamma.cs.unc.edu/RVO2/
  * https://github.com/PathPlanning/ORCA-algorithm implementation of ORCA algorithm
  * https://www.red3d.com/cwr/ (need to install CheerpJ to see the java applets)

## List of problems enncountered and solution found


### How to organize the logic of the code ?

  * Using the ECS pattern with the Concord library currently solve this problem

### How to handle Joystick and combination of inputs (diagonal movement) ?

  * Baton's library provide abstraction for this and directly give you the angle / relative delta x/y
