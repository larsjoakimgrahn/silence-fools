import SwiftUI
import SimplyCoreAudio
import Combine
import HotKey
import BezelNotification

final class SilenceFoolsViewModel: ObservableObject {
    @Published var icon = "mic.fill"
    @Published var simplyCA = SimplyCoreAudio()

    let channel: UInt32 = 0
    let scope: Scope = Scope.input
    
    private var muteChangeNotification: AnyCancellable?
    
    let hotKey = HotKey(key: .m, modifiers: [.command, .shift])
    
    init() {
        muteChangeNotification = NotificationCenter.default.publisher(for: .deviceMuteDidChange).sink(receiveValue: { _ in
            self.updateIconBasedOnMuteState()
        })
        
        updateIconBasedOnMuteState()
        hotKey.keyDownHandler = { self.toggleMuteOfDefaultInputDevice() }
        
    }
    
    deinit {
        muteChangeNotification?.cancel()
    }
    
    func updateIconBasedOnMuteState() {
        let defaultInputDevice = self.simplyCA.defaultInputDevice
        let isMuted = defaultInputDevice?.isMuted(channel: self.channel, scope: self.scope)
        
        guard isMuted != nil else { return }
        
        if (isMuted == true) {
            self.icon = "mic.slash.fill"
            let icon = #imageLiteral(resourceName: "Muted-Image")
            NotificationBezel.show(messageText: "Muted", icon: icon, timeToLive: .short)
            defaultInputDevice?.setVolume(100, channel: self.channel, scope: self.scope)
        } else {
            let icon = #imageLiteral(resourceName: "Unmuted-Image")
            NotificationBezel.show(messageText: "Unmuted", icon: icon, timeToLive: .short)
            defaultInputDevice?.setVolume(0, channel: self.channel, scope: self.scope)
        }
    }
    
    func toggleMuteOfDefaultInputDevice() {
        let device = simplyCA.defaultInputDevice
        let isMuted = device?.isMuted(channel: channel, scope: scope) ?? false
        device?.setMute(!isMuted, channel: channel, scope: scope)
    }
}
   
@main
struct SilenceFoolsApp: App {
    @ObservedObject var viewModel : SilenceFoolsViewModel = SilenceFoolsViewModel()

    var body: some Scene {
        MenuBarExtra(viewModel.icon, systemImage: "\(viewModel.icon)") {
            Button("Toggle Mute") {
                viewModel.toggleMuteOfDefaultInputDevice()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
        
        
    }
}
