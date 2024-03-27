---
title: "Assembly Instructions"
date: 2024-03-12
---
First, we attach the heat sinks to the pis. The GeeekPi Cluster Case comes with four heat sinks for each pi: a short small square, a tall small square, a large square, and a rectangle. All the heat sinks are aligned with the fins in the same direction, and can use the rectangle as a guide for that. With that in mind, the following directions are written with the orientation of the pi with the USB and ethernet ports on the right, facing right. The rectangle heat sink goes on the black rectangle component on the pi. The large square goes on the silver square component directly to the left of the rectangle. The short small square goes on the smaller black square component to the right of the rectangle, closer to the top of the board. The tall small square goes on the slightly larger black square component to the right of the rectangle, slightly closer to the bottom of the board.

Next, we primarily follow the instructions on the GeeekPi Cluster Case assembly. However, we replace the regular screws in step 1 at the bottom of the case assembly with extra standoffs: For the SSD to fit, we use standoffs that are about 3/8 inches tall.

We assemble the pis such that the pi on top (with the exposed GPIO header pins) is the one with 2GB RAM. 

We assembled the fans such that the label side of the fan is facing the pi it is intending to cool. When connecting the fan to the pi underneath it, connect the red (5V) wire to the top left GPIO pin header, and the black (GND) wire to the top third-from-left GPIO pin header.

[//]: # ![Assembled bramble housing with pis and fans:](assets/images/IMG_20240312_232846890.jpg)

<img src="assets/images/IMG_20240312_232846890.jpg">
 