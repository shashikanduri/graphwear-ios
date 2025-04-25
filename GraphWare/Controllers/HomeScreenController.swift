import Foundation
import FirebaseFirestore
import CoreXLSX

class HomeScreenController: ObservableObject {
    
    private let db = Firestore.firestore()
    private let userIdKey = "bluetooth_user_id"
    private let userNameKey = "user_name"
    

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
