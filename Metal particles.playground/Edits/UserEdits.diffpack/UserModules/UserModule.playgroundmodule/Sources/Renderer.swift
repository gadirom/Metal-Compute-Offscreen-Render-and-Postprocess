

//This module contains DelegateRenderer class and MetalView class

import SwiftUI
import MetalKit
import PlaygroundSupport
import MetalPerformanceShaders

struct Particle{
    var color: float4
    var position: float2
    var velocity: float2
    var size: Float
    var angle: Float
    var angvelo: Float
}

struct Vertex
{
    var position : float2 
    var color : float4
}

public class DelegateRenderer : NSObject, MTKViewDelegate
{
    var colorPixelFormat = MTLPixelFormat(rawValue: 0)!
    var viewportSize : uint2 = [0, 0]
    
    var renderPipelineState : MTLRenderPipelineState!
    var commandQueue : MTLCommandQueue!
    var device : MTLDevice!
    
    var computePiplineState:MTLComputePipelineState!
    
    var particleBuffer : MTLBuffer!
    var vertexBuffer : MTLBuffer!
    
    var targetTexture : MTLTexture!
    
    let vertexCount = 3 * particleCount
    
    public init(device: MTLDevice?, frame: CGRect, colorPixelFormat: MTLPixelFormat) {
        
        super.init()
        self.viewportSize.x = uint(frame.width)
        self.viewportSize.y = uint(frame.height)
        
        self.colorPixelFormat = colorPixelFormat
        
        self.device = device
        commandQueue =  self.device?.makeCommandQueue()
        
        // loading compute Metal functions and creating a Compute Pipeline State
        var library : MTLLibrary!
        
        do{ library = try self.device?.makeLibrary(source: metalFunctions, options: nil)
        }catch{print(error)}
        
        let particleFunction = library?.makeFunction(name: "particleFunction")
        
        do{ computePiplineState = try self.device?.makeComputePipelineState(function: particleFunction!)
        }catch{print(error)}
        
        //loading render Metal functions and setting up a Render Pipeline State
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "fragmentShader")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.label = "Render Pipeline"
        pipelineStateDescriptor.vertexFunction = vertexFunction
        pipelineStateDescriptor.fragmentFunction = fragmentFunction
        
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = colorPixelFormat
        pipelineStateDescriptor.colorAttachments[0].isBlendingEnabled = true
        
        do{ renderPipelineState = try self.device?.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }catch{print(error)}
        
        //allocating buffers and creating particles
        vertexBuffer = self.device?.makeBuffer(length: MemoryLayout<Vertex>.stride * vertexCount, options: [])
        particleBuffer = self.device?.makeBuffer(length: MemoryLayout<Particle>.stride * particleCount, options: [])
        
        createParticles()
        
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        //this function is called when the view size is changed
        
        //allocating the offscreen texture and setting the viewport size
        let texDescriptor = MTLTextureDescriptor()
        texDescriptor.textureType = MTLTextureType.type2D
        texDescriptor.width = Int(size.width) 
        texDescriptor.height = Int(size.height)
        texDescriptor.pixelFormat = colorPixelFormat
        texDescriptor.usage = [MTLTextureUsage.renderTarget,
                               MTLTextureUsage.shaderRead]
        
        targetTexture = try device?.makeTexture(descriptor: texDescriptor)
        
        viewportSize.x = UInt32(size.width)
        viewportSize.y = UInt32(size.height)
        
    }
    
    public func draw(in view: MTKView) {
        
        view.device = device
        let commandBuffer = commandQueue?.makeCommandBuffer()
        
        // Compute function encoder
        let computeCommandEncoder = commandBuffer?.makeComputeCommandEncoder()
        computeCommandEncoder?.setComputePipelineState(computePiplineState)
        
        computeCommandEncoder?.setBuffer(particleBuffer, offset: 0, index: 0)
        computeCommandEncoder?.setBuffer(vertexBuffer, offset: 0, index: 1)
        computeCommandEncoder?.setBytes(&viewportSize, length: MemoryLayout<uint2>.stride, index: 2)
        
        let w = computePiplineState.threadExecutionWidth
        let h = computePiplineState.maxTotalThreadsPerThreadgroup
        
        var threadsPerThreadGroup = MTLSize(width: w, height: 1, depth: 1)
        var threadgroupsPerGrid = MTLSize(width: particleCount / w, height: 1, depth: 1)
        computeCommandEncoder?.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
        
        computeCommandEncoder?.endEncoding()
        
        // Render pass encoder
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else {return}
        
        renderPassDescriptor.colorAttachments[0].texture = targetTexture
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreAction.store
        renderPassDescriptor.colorAttachments[0].clearColor = bkgColor
        
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        commandEncoder?.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewportSize.x), height: Double(viewportSize.y), znear: 0.0, zfar: 1.0))
        
        commandEncoder?.setRenderPipelineState(renderPipelineState)
        
        commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder?.setVertexBytes(&viewportSize, length: MemoryLayout<uint2>.stride, index: 1)
        
        commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
        
        commandEncoder?.endEncoding()
        
        //setting up Metal Performance Shaders
        let blur = MPSImageGaussianBlur(device: device, sigma: blurRadius)
        
        let laplacian = MPSImageLaplacian(device: device)
        laplacian.bias = laplacianBias
        
        let dilate = MPSImageAreaMax(device: device, kernelWidth: dilateSize, kernelHeight: dilateSize)
        
        let copyAllocator: MPSCopyAllocator =
            {
                (kernel: MPSKernel, buffer: MTLCommandBuffer, texture: MTLTexture) -> MTLTexture in
                
                let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                    pixelFormat: texture.pixelFormat,
                    width: texture.width,
                    height: texture.height,
                    mipmapped: false)
                
                return buffer.device.makeTexture(descriptor: descriptor)!
            }
        
        //encoding Metal Performance Shaders
        laplacian.encode(commandBuffer: commandBuffer!, inPlaceTexture: &targetTexture, fallbackCopyAllocator: copyAllocator)
        dilate.encode(commandBuffer: commandBuffer!, inPlaceTexture: &targetTexture, fallbackCopyAllocator: nil)
        blur.encode(commandBuffer: commandBuffer!, inPlaceTexture: &targetTexture, fallbackCopyAllocator: nil)
        
        //copying the offscreen texture to the screen (drawable)
        guard let drawable = view.currentDrawable else {return}
        
        let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
        let size = MTLSize(width: Int(viewportSize.x), height: Int(viewportSize.y), depth: 1)
        blitEncoder?.copy(from: targetTexture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: size,
                          
                          to: drawable.texture, destinationSlice: 0, destinationLevel: 0, destinationOrigin: MTLOriginMake(0, 0, 0))
        
        blitEncoder?.endEncoding()
        
        //showing drawable and commiting commands to GPU
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        
    }
    
    func createParticles(){
        
        var particles = particleBuffer.contents().bindMemory(to: Particle.self, capacity: MemoryLayout<Particle>.stride * particleCount)
        
        let x = Float(viewportSize.x)
        let y = Float(viewportSize.y)
        
        for i in 0..<particleCount{
            let red: Float = Float(Int.random(in: 0..<resolution))/Float(resolution)
            let green: Float = Float(Int.random(in: 0..<resolution))/Float(resolution)
            let blue: Float = Float(Int.random(in: 0..<resolution))/Float(resolution)
            
            let veloX = (green - 0.5) * speed
            let veloY = (blue - 0.5) * speed
            
            let size = sizeOfTrianglesMin * (1 - red) + sizeOfTrianglesMax * red
            
            let angle = blue
            
            let posX = Float(arc4random_uniform(UInt32(x))) - x/2
            let posY = Float(arc4random_uniform(UInt32(y))) - y/2
            
            let color = float4(red, green, blue, 1)
            
            let angvelo = Float.random(in: -1..<1) * angSpeed
            
            particles[i] = Particle(color: color,
                                    position: float2(posX,posY),
                                    velocity: float2(veloX, veloY), 
                                    size: size, 
                                    angle: angle, angvelo: angvelo)
        }
    }
    
}

public class MetalView :MTKView {
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        
        super.init(frame: frameRect, device: device)
        
        self.isPaused = false
        self.enableSetNeedsDisplay = false 
        
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
