import UIKit
import GPUImage

class FilteringViewController : BaseViewController {
    
    fileprivate enum Segues : String {
        case save = "segSave"
    }
    
    /// URL of the video file to be filtered.
    /// - Attention: Must be set before presenting `FilteringViewController`.
    var videoURL: URL!
    
    fileprivate var video: GPUImageMovie!
    
    fileprivate var currentFilter : Filter? {
        willSet {
            if let currentFilter = currentFilter, vPreview != nil {
                currentFilter.output.removeTarget(vPreview)
            }
        }
        didSet {
            if let currentFilter = currentFilter, vPreview != nil {
                currentFilter.output.addTarget(vPreview)
                vPreview.setInputRotation(kGPUImageRotateRight, at: 0)
                // Enable full-size processing.
//                currentFilter.output.forceProcessing(atSizeRespectingAspectRatio: CGSize.zero)
                lName.text = currentFilter.name
                biSave.isEnabled = currentFilter.output != video
            }
        }
    }
    
    @IBOutlet private weak var vPreview: GPUImageView!
    @IBOutlet private weak var cvFilters: UICollectionView!
    @IBOutlet private weak var lName: UILabel!
    @IBOutlet weak private var biSave: UIBarButtonItem!
    
    fileprivate var filters: [Filter]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let flow = cvFilters.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.itemSize = CGSize(width: 90, height: 120)
            flow.minimumLineSpacing = 1
            flow.minimumInteritemSpacing = 1
        }
        video = GPUImageMovie(url: videoURL)
        video.shouldRepeat = true
        loadSupportedFilters()
        currentFilter = filters.first
        video.startProcessing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        filters.forEach {
            guard let filter = $0.output as? GPUImageInput else {
                return
            }
            video.addTarget(filter)
        }
//        video.startProcessing()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Some clean-up
        filters.forEach {
            guard let filter = $0.output as? GPUImageInput, $0.name != currentFilter?.name else {
                return
            }
            video.removeTarget(filter)
        }
//        video.endProcessing()
    }
    
    func loadSupportedFilters() {
        filters = [Filter(name: "None", output: video),
                Filter(name: "Amaro", output: IFAmaroFilter()),
                Filter(name: "Brannan", output: IFBrannanFilter()),
                Filter(name: "Earlybird", output: IFEarlybirdFilter()),
                Filter(name: "LordKelvin", output: IFLordKelvinFilter()),
                Filter(name: "Color Invert", output: GPUImageColorInvertFilter()),
                Filter(name: "Hue", output: GPUImageHueFilter()),
                Filter(name: "Sepia", output: GPUImageSepiaFilter()),
                Filter(name: "Grayscale", output: GPUImageGrayscaleFilter())]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier, id == Segues.save.rawValue else {
            print("Not supported segue.")
            return
        }
        
        guard let controller = segue.destination as? SaveViewController else {
            print("Invalid destination view controller.")
            return
        }
        guard let currentFilter = currentFilter else {
            print("Filter was not set.")
            return
        }
        controller.filter = currentFilter
        controller.video = video
    }
    
    @IBAction func saveAction(_ sender: UIBarButtonItem) {
        if let currentFilter = currentFilter, currentFilter.output != video {
            self.performSegue(withIdentifier: Segues.save.rawValue, sender: self)
        } else {
            notifyAlert("You haven't applied any filters.")
        }
    }
}

extension FilteringViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filterCell", for: indexPath)
        if let cell = cell as? FilterCell {
            cell.configure(withFilter: filters[indexPath.item])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // Ensure any filtering operations on cell has been stopped.
        if let cell = cell as? FilterCell {
            cell.stop()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentFilter = filters[indexPath.item]
    }
}
