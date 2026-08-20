import Foundation
import UIKit
import CoreLocation

struct EmergencyContact: Codable, Identifiable {
    var id = UUID()
    var name: String
    var phoneNumberWithCountryCode: String
}

class WhatsAppDispatcher {
    static let shared = WhatsAppDispatcher()
    
    func sendEmergencyLocation(to contact: EmergencyContact, location: CLLocation) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let mapsUrl = "https://maps.google.com/?q=\(lat),\(lon)"
        
        let messageText = """
        🚨 EMERGENCY ALERT 🚨
        I have been involved in a serious accident. Here is my current location:
        \(mapsUrl)
        
        Timestamp: \(Date().formatted(date: .abbreviated, time: .standard))
        Speed: \(max(0, Int(location.speed * 3.6))) km/h
        Please send medical assistance immediately!
        """
        
        guard let encodedMessage = messageText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let whatsappURLString = "whatsapp://send?phone=\(contact.phoneNumberWithCountryCode)&text=\(encodedMessage)"
        
        if let whatsappURL = URL(string: whatsappURLString), UIApplication.shared.canOpenURL(whatsappURL) {
            UIApplication.shared.open(whatsappURL, options: [:], completionHandler: nil)
        } else {
            let webURLString = "https://api.whatsapp.com/send?phone=\(contact.phoneNumberWithCountryCode)&text=\(encodedMessage)"
            if let webURL = URL(string: webURLString) {
                UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
            }
        }
    }
}
