import SwiftUI
import KeyHolder
import Defaults
import Magnet

extension Defaults.Keys {
    static let hotKey = Key<KeyCombo?>("hotKey", default: KeyCombo(key: .m, cocoaModifiers: [.shift, .command]))
    static let showNotifications = Key<Bool>("showNotifications", default: true)
}

extension KeyCombo: _DefaultsSerializable {}

struct RepresentedKeyRecordView: NSViewRepresentable {
    private let didChange: ((KeyCombo?) -> Void)?
    init(didChange: ((KeyCombo?) -> Void)?) {
        self.didChange = didChange
    }
    
    func makeNSView(context: Context) -> KeyHolder.RecordView {
        let view = RecordView(frame: CGRect.zero)
        view.keyCombo = Defaults[.hotKey]
        view.didChange = didChange
        return view
    }
    
    func updateNSView(_ nsView: KeyHolder.RecordView, context: Context) {}
    
    typealias NSViewType = RecordView
    
}

struct GeneralSettingsView: View {
    @Default(.showNotifications) var showNotifications

    let keyRecordView = RepresentedKeyRecordView(didChange: { combo in
        guard let combo = combo else { return }
        Defaults[.hotKey] = KeyCombo(QWERTYKeyCode: combo.QWERTYKeyCode, carbonModifiers: combo.modifiers)
    })

    var body: some View {
        VStack {
            Text(verbatim: "Toggle Mute hotkey")
                .font(.system(size: 20, weight: .heavy, design: .default))
            keyRecordView
                .frame(idealWidth: 550, idealHeight: 100)
                .scaleEffect(0.5)
                .fixedSize()
                .padding(0)
            Divider()
            Text(verbatim: "Show notifications on mute change")
                .font(.system(size: 20, weight: .heavy, design: .default))
            Toggle("", isOn: $showNotifications)
                .toggleStyle(.switch)
                .scaleEffect(2)
                .padding(15)

        }
    }
}

struct SettingsView: View {
    var body: some View {
            GeneralSettingsView()
                .frame(width: 450, height: 320)
    }
}
