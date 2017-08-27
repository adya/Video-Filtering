
class BaseViewController : UIViewController {
    func notifyAlert(_ message: String) {
        guard !message.isEmpty else {
            return
        }
        let alert = UIAlertController(title: "Video Filter", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
}
