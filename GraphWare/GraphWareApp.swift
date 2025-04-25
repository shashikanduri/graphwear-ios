
import FirebaseCore
import SwiftUI

@main
struct GraphWareApp: App {
    @StateObject var bluetoothSimulator = BluetoothSimulator()
    
    init(){
        FirebaseApp.configure();
    }
    
    var body: some Scene {
        WindowGroup {
            MainView().environmentObject(bluetoothSimulator)
        }
    }
}

