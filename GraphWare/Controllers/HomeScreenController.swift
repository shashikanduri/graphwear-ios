import Foundation
import FirebaseFirestore
import CoreXLSX

class HomeScreenController: ObservableObject {
    @Published var selectedOption: String = "Sensor One"
    
    private let db = Firestore.firestore()
    private let userIdKey = "bluetooth_user_id"
    private let userNameKey = "user_name"
    
    let options = ["Sensor One", "Sensor Two"]
    private let storageKey = "selected_dropdown_value"

    init() {
        if let saved = UserDefaults.standard.string(forKey: storageKey) {
            selectedOption = saved
        } else {
            UserDefaults.standard.set("Sensor One", forKey: storageKey)
            selectedOption = "Sensor One"
        }
        
    }

    func storeSelectionInLocalStorage() {
        UserDefaults.standard.set(selectedOption, forKey: storageKey)
    }
    

    func registerUser(name: String, completion: @escaping (Bool) -> Void) {

        let existingUserId = UserDefaults.standard.string(forKey: userIdKey)
        if existingUserId?.isEmpty == false {
            UserDefaults.standard.set(.none, forKey: userNameKey)
            UserDefaults.standard.set(.none, forKey: userIdKey)
        }

        Task {
            do {
                let lastUser = try await db.collection("users")
                    .order(by: "user_id", descending: true)
                    .limit(to: 1)
                    .getDocuments()

                let lastUserID = lastUser.documents.first?.data()["user_id"] as? Int ?? 0
                let newID = lastUserID + 1
                let newIDString = "\(newID)"

                try await db.collection("users").addDocument(data: [
                    "user_id": newID,
                    "user_name": name,
                    "installed_on": Date().timeIntervalSince1970
                ])

                UserDefaults.standard.set(newIDString, forKey: userIdKey)
                UserDefaults.standard.set(name, forKey: userNameKey)

                print("✅ User registered: \(name) (ID \(newID))")

                DispatchQueue.main.async {
                    completion(true)
                }

            } catch {
                print("❌ Failed to register user: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
}
