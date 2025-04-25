import SwiftUI

struct SensorSelectionScreen: View {
    @StateObject var controller = HomeScreenController()
    @EnvironmentObject var bluetoothSimulator: BluetoothSimulator

    @State private var showSensor1Dialog = false
    @State private var showSensor2Dialog = false

    var userName: String {
        UserDefaults.standard.string(forKey: "user_name") ?? "No User Assigned"
    }

    var body: some View {
        ZStack {
            Color(red: 41/255, green: 41/255, blue: 41/255)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()

                Image("graphwear")
                    .resizable()
                    .frame(width: 150, height: 100)
                    .padding(.bottom, 10)

                Text("\(userName)'s Lactate Monitor")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .padding(.bottom, 10)

                sensorSection(title: "Sensor 1",
                              value1: bluetoothSimulator.sensor1Channel1,
                              value2: bluetoothSimulator.sensor1Channel2,
                              value3: bluetoothSimulator.sensor1Channel3,
                              showDialog: $showSensor1Dialog)

                sensorSection(title: "Sensor 2",
                              value1: bluetoothSimulator.sensor2Channel1,
                              value2: bluetoothSimulator.sensor2Channel2,
                              value3: bluetoothSimulator.sensor2Channel3,
                              showDialog: $showSensor2Dialog)

                Spacer()
            }
            .padding(.horizontal, 30)
        }
    }

    private func sensorSection(title: String, value1: Double, value2: Double, value3: Double, showDialog: Binding<Bool>) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .foregroundColor(.white)
                    .font(.headline)
                    .padding(10)
            }

            HStack(spacing: 30) {
                channelCircleView(title: "Channel 1", value: value1)
                channelCircleView(title: "Channel 2", value: value2)
                channelCircleView(title: "Channel 3", value: value3)
            }
        }
    }

    private func channelCircleView(title: String, value: Double) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 90, height: 90)

                Text(String(format: "%.2f", value))
                    .foregroundColor(.white)
                    .font(.headline)
                    .bold()
            }

            Text(title)
                .foregroundColor(.gray)
                .font(.footnote)
        }
    }
}
