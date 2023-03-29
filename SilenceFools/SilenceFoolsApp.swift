import SwiftUI
import SimplyCoreAudio
import Combine
import HotKey
import BezelNotification
import Defaults

final class SilenceFoolsViewModel: ObservableObject {
    @Published var icon = "mic.fill"
    @Published var simplyCA = SimplyCoreAudio()

    let channel: UInt32 = 0
    let scope: Scope = Scope.input
    
    private var muteChangeNotification: AnyCancellable?
    
    private var showNotifications: Bool = false
    
    var hotKey: HotKey? = HotKey(key: .m, modifiers: [.shift, .command])
    
    init() {
        muteChangeNotification = NotificationCenter.default.publisher(for: .deviceMuteDidChange).sink(receiveValue: { _ in
            self.updateIconBasedOnMuteState()
        })
        
        updateIconBasedOnMuteState()
        
        Task {
            for await value in Defaults.updates(.showNotifications) {
                showNotifications = value
            }
        }
        
        Task {
            for await value in Defaults.updates(.hotKey) {
                
                if let value = value {
                    hotKey = HotKey(key: Key(string: value.key.rawValue) ?? .m, modifiers: NSEvent.ModifierFlags(carbonModifiers: value.modifiers)
                    )
                } else {
                    hotKey = nil
                }
                hotKey?.keyDownHandler = {
                    self.toggleMuteOfDefaultInputDevice()
                }
            }
        }
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
            if (showNotifications) {
                NotificationBezel.show(messageText: "Muted", icon: icon, timeToLive: .short)
            }
            defaultInputDevice?.setVolume(100, channel: self.channel, scope: self.scope)
        } else {
            self.icon = "mic.fill"
            let icon = #imageLiteral(resourceName: "Unmuted-Image")
            if (showNotifications) {
                NotificationBezel.show(messageText: "Unmuted", icon: icon, timeToLive: .short)
            }
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
    @State private var isShowingPreferencesView = false

    var body: some Scene {
        MenuBarExtra(viewModel.icon, systemImage: "\(viewModel.icon)") {
            Button("Toggle Mute") {
                viewModel.toggleMuteOfDefaultInputDevice()
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])
            Button("Preferences...") {
                if #available(macOS 13, *) {
                  NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } else {
                  NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }.keyboardShortcut("q")
        }
        Settings {
            SettingsView()
        }
    }
}
