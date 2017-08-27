import GPUImage

class FilterCell : UICollectionViewCell {
    
    @IBOutlet private var vPreview: GPUImageView!
    @IBOutlet private var lName: UILabel!
    
    private var filter: Filter!
    
    func configure(withFilter filter: Filter) {
        self.filter = filter
//        if !isSelected {
//            self.filter.output.forceProcessing(atSizeRespectingAspectRatio: self.vPreview.bounds.size)
//        }
        vPreview.setInputRotation(kGPUImageRotateRight, at: 0)
        filter.output.addTarget(vPreview)
        lName.text = filter.name
    }
    
    func stop() {
        self.filter?.output.removeTarget(vPreview)
    }
}
