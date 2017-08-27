import GPUImage

struct Filter {
    
    let name : String
    
    let output: GPUImageOutput
    
    init(name: String, output: GPUImageOutput) {
        self.name = name
        self.output = output
    }
}
