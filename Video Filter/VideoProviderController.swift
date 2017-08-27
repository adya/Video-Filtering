import UIKit
import MediaPlayer
import MobileCoreServices

class VideoProviderController: BaseViewController {
    
    /// Segues supported by this `UIViewController`.
    fileprivate enum Segues : String {
        case filtering = "segFiltering"
    }
    
    /// Path to selected video file.
    /// - Note: Once set - will perform segue to next step.
    fileprivate var pickedVideoURL : URL? {
        didSet {
            if pickedVideoURL != nil {
                self.performSegue(withIdentifier: Segues.filtering.rawValue, sender: self)
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let id = segue.identifier, id == Segues.filtering.rawValue else {
            print("Unsupported segue.")
            return
        }
        
        guard let controller = segue.destination as? FilteringViewController else {
            print("Segue's destinations view controller is invalid.")
            return
        }
        
        guard let url = pickedVideoURL else {
            print("Path to video file was not set.")
            return
        }

        controller.videoURL = url
        pickedVideoURL = nil
    }
}

// MARK: - Controller
private extension VideoProviderController {
    
    @IBAction func pickVideoAction(_ sender: UIButton) {
        openVideoPicker()
    }
    
    @IBAction func recordVideoAction(_ sender: UIButton) {
        openVideoRecorder()
    }
}

// MARK: - Navigation
private extension VideoProviderController {
    func openVideoPicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) else {
            notifyAlert("Gallery is not avaialable on this device.")
            return
        }
        
        let picker = createImagePicker()
        picker.sourceType = .savedPhotosAlbum
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.delegate = self
        
        self.present(picker, animated: true, completion: nil)
        
    }
    
    func openVideoRecorder() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            notifyAlert("Camera is not avaialable on this device.")
            return
        }
        
        let picker = createImagePicker()
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.delegate = self
        
        self.present(picker, animated: true, completion: nil)
    }
    
    /// Creates and configures `UIImagePickerController`.
    private func createImagePicker() -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.navigationBar.isTranslucent = false
        picker.navigationBar.barTintColor = self.navigationController?.navigationBar.barTintColor
        picker.navigationBar.tintColor = self.navigationController?.navigationBar.tintColor
        picker.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        return picker
    }
}

// MARK: - UIImagePickedControllerDelegate
extension VideoProviderController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true) {
            if let mediaType = info[UIImagePickerControllerMediaType] as? String,
             mediaType == (kUTTypeMovie as String) {
                
                guard let url = (info[UIImagePickerControllerReferenceURL as String] as? URL) else {
                    return
                }
                if picker.sourceType == .camera {
                    guard UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path) else {
                        return
                    }
                    UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, #selector(self.video(_:didFinishSavingWith:contextInfo:)), nil)
                } else {
                    self.pickedVideoURL = url
                }
            }
        }
    }
    
    @objc private func video(_ url: String, didFinishSavingWith error: NSError?, contextInfo info: AnyObject) {
        if let error = error {
            let alert = UIAlertController(title: "Operation Failed", message: "Video was not save due to an error: \(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            pickedVideoURL = URL(fileURLWithPath: url)
        }
    }
}
