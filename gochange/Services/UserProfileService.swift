import Foundation
import Combine

class UserProfileService: ObservableObject {
    static let shared = UserProfileService()
    
    @Published var firstName: String = UserDefaults.standard.string(forKey: "userFirstName") ?? "User" {
        didSet {
            UserDefaults.standard.set(firstName, forKey: "userFirstName")
        }
    }
    
    @Published var lastName: String = UserDefaults.standard.string(forKey: "userLastName") ?? "Name" {
        didSet {
            UserDefaults.standard.set(lastName, forKey: "userLastName")
        }
    }
    
    private init() {}
}
