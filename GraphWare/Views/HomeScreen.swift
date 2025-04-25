import SwiftUI

struct HomeScreen: View {
    @State private var enteredName: String = ""
    @State private var isRegistered = false
    @StateObject private var controller = HomeScreenController()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 41/255, green: 41/255, blue: 41/255)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    Image("graphwear")
                        .resizable()
                        .frame(width: 150, height: 100)
                        .padding(.bottom, 20)

                    TextField("", text: $enteredName, prompt: Text("Enter your name").foregroundColor(.gray))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .foregroundColor(.black)
                    


                    Button(action: {
                        controller.registerUser(name: enteredName) { success in
                            if success {
                                isRegistered = true
                            }
                        }
                    }) {
                        Text("Register")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(enteredName.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    .disabled(enteredName.isEmpty)
                    .navigationDestination(isPresented: $isRegistered) {
                        SensorSelectionScreen()
                    }

                    Spacer()
                }
            }
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
    }
}
