## Overview
This is a simple Swift Playground Book that let you explore the Apple's [Metal](https://developer.apple.com/metal/) technology on iOS.
Upon running it creates a big number of triangular particles with random properties that move on screen demonstrating interference patterns.

The code was created entirely on an iPad Pro using the free [Swift Playgrounds](https://apps.apple.com/ru/app/swift-playgrounds/id908519492?l=en) app.

## Contents
The Playground Book consists of three pages: `Main page` that prepares Playground’s LiveView, `Renderer` page containing the declaration of a renderer delegate function, `MetalFunctions` page that contain the code of Metal functions, and `Main Constants` page where you can tweak most of the properties of the particles and shaders by changing the values of the constants declared there.

## Metal Pipeline
The renderer makes use of 4 different kinds of Metal functions that are successively encoded into the command buffer via proper pipelines. The order of encoding is as follows: compute function (compute the vertices for each triangular particle), render function (render triangles to an offscreen texture), shader function (returns interpolated color for each rendered pixel), Metal performance shaders (modify the rendered image), the Blit command (copies the image onto the screen).

## Metal Functions
Three of the above mentioned functions are written in [Metal Shading Language](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf). These are: the compute function, the render function, and the shader function. Since Swift Playgrounds app won’t let you create a .metal file these functions are placed in the Swift code as a value of a string constant (hence, no Metal language is detected by GitHub for this repo), which is then used to initialize an MTLLibrary.

## Interference Patterns
The rendered particles demonstrate interference patterns that somewhat resemble the image observed in the [double-slit experiment](https://en.m.wikipedia.org/wiki/Double-slit_experiment#/media/File%3AWave-particle_duality.gif) in physics. 

Though, in this case the patterns move and change over time creating an illusion of swarming behavior as though each particle is being controlled to “participate” in these patterns. 

Yet all the particles have fixed random velocities that they get at start and each one of them moves with constant speed without being ”aware” of each other’s existence, and the interference patterns appear, in fact, as an effect of initial discretization of the velocities. 

The number of different initial velocities is limited by a small amount (e.g., 100) hence particles with identical velocities form separate groups that superimpose on the screen and create patterns. 

Thus, simple starting condition of the system of particles leads to a very complex [emergent](https://en.m.wikipedia.org/wiki/Emergence) behaviour of the system.

## Installation
Simply copy the root folder into the `Playgrounds` folder on your iCloud drive and the book will become available in the Swift Playgrounds app.

Alternatively, the folder may be placed anywhere on the iPad and then opened via `Locations` menu in the app.
