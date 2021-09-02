<p align="center">
   <img src="assets/Metal.svg" alt="Metal Logo & Name"/>
</p>
<p align="center">
    <img src="https://img.shields.io/badge/platforms-iPadOS_14_-blue.svg" alt="iPadOS" />
    <a href="https://swift.org/about/#swiftorg-and-open-source"><img src="https://img.shields.io/badge/Swift-5.3-orange.svg" alt="Swift 5.3" /></a>
    <a href="https://developer.apple.com/metal/"><img src="https://img.shields.io/badge/Metal-2.4-green.svg" alt="Metal 2.4" /></a>
    <a href="https://apps.apple.com/ru/app/swift-playgrounds/id908519492?l=en"><img src="https://img.shields.io/badge/SwiftPlaygrounds-3.4.1-orange.svg" alt="Swift Playgrounds 3" /></a>
   <a href="https://en.wikipedia.org/wiki/MIT_License"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License: MIT" /></a>
    
</p>

## Overview
This is a simple Swift Playground Book that explores the Apple's [Metal](https://developer.apple.com/metal/) technology on iOS.

Upon running it shows a big number of 2D triangular particles processed by metal shaders that move on screen demonstrating emergent patterns.

The code was created entirely on an iPad Pro using the free [Swift Playgrounds](https://apps.apple.com/ru/app/swift-playgrounds/id908519492?l=en) app.

## Contents
The Playground Book consists of three pages: 
- [`Main`](https://github.com/gadirom/Metal-Compute-Offscreen-Render-and-Postprocess/blob/master/Metal%20particles.playgroundbook/Edits/UserEdits.diffpack/Chapters/Chapter1.playgroundchapter/Pages/My%20Playground.playgroundpage/main.swift.delta) page that prepares Playground’s LiveView, 
- [`Renderer`](https://github.com/gadirom/Metal-Compute-Offscreen-Render-and-Postprocess/blob/master/Metal%20particles.playgroundbook/Edits/UserEdits.diffpack/UserModules/UserModule.playgroundmodule/Sources/Renderer.swift) page containing the declaration of a [renderer delegate](https://developer.apple.com/documentation/metal/basic_tasks_and_concepts/using_metal_to_draw_a_view_s_contents) function, 
- [`MetalFunctions`](https://github.com/gadirom/Metal-Compute-Offscreen-Render-and-Postprocess/blob/master/Metal%20particles.playgroundbook/Edits/UserEdits.diffpack/UserModules/UserModule.playgroundmodule/Sources/MetalFunctions.swift) page that contain the code of Metal functions,
- [`Main Constants`](https://github.com/gadirom/Metal-Compute-Offscreen-Render-and-Postprocess/blob/master/Metal%20particles.playgroundbook/Edits/UserEdits.diffpack/UserModules/UserModule.playgroundmodule/Sources/Main%20constants.swift) page where you can tweak most of the properties of the particles and shaders by changing the values of the constants declared there.

The code is buried deep in the folders structure of the book.
Use the links above to jump directly to a particular page if you want to view it without loading it into Swift Playdrounds App.

## Metal Pipeline
The renderer delegate makes use of 5 different kinds of Metal functions that are successively encoded during a [draw call](https://developer.apple.com/documentation/metalkit/mtkview/1535943-draw) into the command buffer directly or via proper pipelines.
The order of encoding of the functions is as follows:

1. Compute pipeline state: compute function (computes the vertices for each triangular particle)
2. Render pipeline state: render function (renders triangles to an offscreen texture), shader function (returns interpolated color for each rendered pixel)
3. Metal performance shaders (modify the rendered image with Laplacian, Dilate, and Gaussian Blur emulation)
4. Blit command (copies the final image into the [drawable](https://developer.apple.com/documentation/metal/drawable_objects) texture)

## Metal Functions
Three of the above mentioned functions are written in [Metal Shading Language](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf). These are: the compute function, the render function, and the shader function.

Since Swift Playgrounds app won’t let you create a .metal file these functions are placed in the Swift code as a value of a string constant (hence, no Metal language is detected by GitHub for this repo), which is then used to initialize a functions library.

## Interference Patterns
The rendered particles demonstrate interference patterns that somewhat resemble the image observed in the [double-slit experiment](https://en.m.wikipedia.org/wiki/Double-slit_experiment#/media/File%3AWave-particle_duality.gif) in physics. 

Though, in this case the patterns move and change over time creating an illusion of swarming behavior as though each particle is being controlled to “participate” in these patterns. 

Yet all the particles have fixed random velocities that they get at start and maintain during their entire existance, i.e. each one of the particles moves with constant speed without being ”aware” of each other’s speed or location. 

The interference patterns appear, in fact, as an effect of initial discretization of the velocities. The number of different initial velocities is limited by a small amount (e.g., 100) hence particles with identical velocities form separate groups that superimpose on the screen and create patterns. 

Thus, a simple starting condition of the system of particles leads to a very complex [emergent](https://en.m.wikipedia.org/wiki/Emergence) behaviour of the system.

## Installation
If you are reading this from an iPad then download the repo and unzip it. Then tap on `Metal particles` file and it will be opened by the Swift Playgrounds app.

Alternatively, the unzipped file may be placed anywhere on the iPad and then opened via `Locations` menu from the app.
