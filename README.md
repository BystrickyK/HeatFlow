# HeatFlow
118x118 grid, set point given by a binary image
The state dimension rises rapidly with the size of the image. All matrices had to be defined as sparse matrices for both time and memory purposes.

Animated simulations are below. Each simulation step, a random spot on the plate gets cooled down to demonstrate the controller's ability to deal with disturbances.

LQ-MPC, ref tracking, delta U input, unbounded
https://user-images.githubusercontent.com/55796835/119216472-2dd99780-bad4-11eb-88a6-29e25a76a7b4.mp4

Bounded, asymmetric bounds, computed using quadprog. Each computation took ~ 1.8 seconds, much longer than the previous unconstrained case.
https://user-images.githubusercontent.com/55796835/119216739-c02e6b00-bad5-11eb-8395-58ae2986e512.mp4
