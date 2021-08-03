
import MetalKit

public let particleCount = 50000
public let startSize : CGFloat = 100 // Size of the initial area for particles 
public let resolution : Int = 100 //Resolution of speed randomization, i.e number of possible different speeds for particles

public let sizeOfTrianglesMin : Float = 2
public let sizeOfTrianglesMax : Float = 10

public let speed : Float = 10
public let angSpeed : Float = 0.1

public let blurRadius : Float = 2.5
public let dilateSize : Int = 4
public let laplacianBias : Float = -0.5

public let bkgColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
