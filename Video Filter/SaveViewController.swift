import UIKit
import GPUImage
import Photos

class SaveViewController: BaseViewController {

    var filter: Filter!
    var video: GPUImageMovie!
    
    fileprivate var writer: GPUImageMovieWriter!
    
    @IBOutlet weak private var lName: UILabel!
    @IBOutlet weak private var vPreview: GPUImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lName.text = filter.name
        filter.output.addTarget(vPreview)
        vPreview.setInputRotation(kGPUImageRotateRight, at: 0)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        filter.output.removeTarget(vPreview)
        vPreview.endProcessing()
    }
    @IBAction func confirmAction(_ sender: UIBarButtonItem) {
        promptSaveAlert()
    }
    
    var defaultVideoFilename: String {
        let result = PHAsset.fetchAssets(withALAssetURLs: [video.url], options: nil)
        let fileName = PHAssetResource.assetResources(for: result.firstObject!).first!.originalFilename as NSString
        let name = fileName.deletingPathExtension
        return "\(name)_\(filter.name)"
    }
}

// MARK: - Interactions.
private extension SaveViewController {
    func promptSaveAlert() {
        
        let defaultFilename = defaultVideoFilename
        let alert = UIAlertController(title: "Video Filter", message: "Video filtered with \(filter.name) filter will be saved as \(defaultFilename). If you want to use different name for a file, please, enter desired name below.", preferredStyle: .alert)
        
        alert.addTextField { tfFilename in
            tfFilename.placeholder = "\(defaultFilename)"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            var name : String = defaultFilename
            if let text = alert.textFields?.first?.text,
                !text.isEmpty {
                name = (text as NSString).deletingPathExtension
            }
            
            self.saveVideo(named: name)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveVideo(named name: String) {
        let saveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name).appendingPathExtension(video.url.pathExtension)
        
        if FileManager.default.fileExists(atPath: saveURL.path) {
            try? FileManager.default.removeItem(at: saveURL)
        }
        
        guard let track = AVAsset(url: video.url).tracks(withMediaType: AVMediaTypeVideo).first else {
            print("Failed to get video size.")
            return
        }
        let size = track.naturalSize.applying(track.preferredTransform)
        let videoSize = CGSize(width: fabs(size.width), height: fabs(size.height))
        
        writer = GPUImageMovieWriter(movieURL: saveURL, size: videoSize, fileType: AVFileTypeQuickTimeMovie, outputSettings: nil)!
        writer.shouldPassthroughAudio = true
        writer.assetWriter.movieFragmentInterval = kCMTimeInvalid
        writer.completionBlock = { [unowned self] in
            self.filter.output.removeTarget(self.writer)
            self.writer.finishRecording()
            self.writer = nil
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: saveURL)
            }) { saved, error in
                print(String(describing: error))
                if saved {
                    self.notifyAlert("Video has been successfully saved.")
                    self.navigationController?.popToRootViewController(animated: true)
                    try? FileManager.default.removeItem(at: saveURL)
                }
            }
        }
        
        filter.output.addTarget(writer)
        video.audioEncodingTarget = writer
        video.enableSynchronizedEncoding(using: writer)
        writer.startRecording()
        
    }
}
