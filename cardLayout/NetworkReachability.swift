
import UIKit
import Alamofire

class NetworkReachability {
  static let shared = NetworkReachability()
  let reachabilityManager = NetworkReachabilityManager(host: "www.google.com")
  let offlineAlertController: UIAlertController = {
    let alertController = UIAlertController(title: "Network error", message: "Unable to contact the server", preferredStyle: .alert)

    let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
        // handle response here.
    }

    alertController.addAction(OKAction)
    return alertController
  }()

  func startNetworkMonitoring() {
    reachabilityManager?.listener = { status in
            switch status {

                case .notReachable:
                    print("The network is not reachable")
                    self.showOfflineAlert()
                case .unknown :
                    print("It is unknown whether the network is reachable")
                    self.showOfflineAlert()
                case .reachable(.ethernetOrWiFi):
                    print("The network is reachable over the WiFi connection")
                    self.dismissOfflineAlert()
                case .reachable(.wwan):
                    print("The network is reachable over the WWAN connection")
                    self.dismissOfflineAlert()
                }
            }

            // start listening
            reachabilityManager?.startListening()
  }
    
    

  func showOfflineAlert() {
    let rootViewController = UIApplication.shared.windows.first?.rootViewController
    
    if (!offlineAlertController.isModal1()){
        rootViewController?.present(offlineAlertController, animated: true, completion: nil)
    }
    
  }

  func dismissOfflineAlert() {
    let rootViewController = UIApplication.shared.windows.first?.rootViewController
    rootViewController?.dismiss(animated: true, completion: nil)
  }
}
