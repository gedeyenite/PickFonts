import SwiftUI
import AppKit

struct FontItem: Identifiable, Hashable {
    let id: String
    let name: String
    let family: String
}

final class FontPickerViewModel: ObservableObject {
    @Published var sampleText: String = "The quick brown fox jumps over the lazy dog"
    @Published var fontSize: Double = 28.0
    @Published var searchQuery: String = ""
    @Published var removedFontIDs: Set<String> = []
    
    let allFonts: [FontItem]
    
    init() {
        let families = NSFontManager.shared.availableFontFamilies.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
        
        var items: [FontItem] = []
        for fam in families {
            let memberList = NSFontManager.shared.availableMembers(ofFontFamily: fam) ?? []
            if let firstMember = memberList.first, let postscriptName = firstMember[0] as? String {
                items.append(FontItem(id: postscriptName, name: postscriptName, family: fam))
            } else {
                items.append(FontItem(id: fam, name: fam, family: fam))
            }
        }
        self.allFonts = items
    }
    
    var visibleFonts: [FontItem] {
        allFonts.filter { item in
            !removedFontIDs.contains(item.id) &&
            (searchQuery.isEmpty || item.family.localizedCaseInsensitiveContains(searchQuery))
        }
    }
    
    var summaryCountText: String {
        "Showing \(visibleFonts.count) of \(allFonts.count) fonts"
    }
    
    var availableLetters: Set<Character> {
        Set(visibleFonts.compactMap { $0.family.uppercased().first }.filter { $0.isLetter })
    }
    
    func removeFont(_ item: FontItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            _ = removedFontIDs.insert(item.id)
        }
    }
    
    func restoreAll() {
        withAnimation(.easeInOut(duration: 0.2)) {
            removedFontIDs.removeAll()
        }
    }
    
    func copyFontNames() {
        let text = visibleFonts.map { $0.family }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

struct ContentView: View {
    @StateObject private var vm = FontPickerViewModel()
    
    private let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    
    var body: some View {
        VStack(spacing: 0) {
            // Control Header
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    TextField("Enter preview sample text...", text: $vm.sampleText)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack(spacing: 6) {
                        Text("Size: \(Int(vm.fontSize))pt")
                            .font(.subheadline)
                            .frame(width: 75, alignment: .trailing)
                        Slider(value: $vm.fontSize, in: 12...72, step: 1)
                            .frame(width: 130)
                    }
                }
                
                HStack(spacing: 12) {
                    TextField("Filter by name...", text: $vm.searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 240)
                    
                    Text(vm.summaryCountText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Copy Font Names") {
                        vm.copyFontNames()
                    }
                    
                    Button("Restore All (\(vm.removedFontIDs.count))") {
                        vm.restoreAll()
                    }
                    .disabled(vm.removedFontIDs.isEmpty)
                }
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // A-Z Quick Jump Bar
            HStack(spacing: 2) {
                ScrollViewReader { proxy in
                    HStack(spacing: 2) {
                        ForEach(alphabet, id: \.self) { letter in
                            let isEnabled = vm.availableLetters.contains(letter)
                            Button(action: {
                                if let target = vm.visibleFonts.first(where: {
                                    $0.family.uppercased().hasPrefix(String(letter))
                                }) {
                                    withAnimation {
                                        proxy.scrollTo(target.id, anchor: .top)
                                    }
                                }
                            }) {
                                Text(String(letter))
                                    .font(.system(size: 11, weight: .bold))
                                    .frame(maxWidth: .infinity, minHeight: 22)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(isEnabled ? .primary : Color.secondary.opacity(0.35))
                            .disabled(!isEnabled)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Font List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(vm.visibleFonts) { item in
                            HStack(alignment: .center, spacing: 16) {
                                Button(action: { vm.removeFont(item) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                                .help("Dismiss font")
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.family)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    Text(vm.sampleText.isEmpty ? item.family : vm.sampleText)
                                        .font(Font.custom(item.name, size: CGFloat(vm.fontSize)))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .id(item.id)
                            
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 520)
    }
}

@main
struct ModernFontPickerApp: App {
    var body: some Scene {
        WindowGroup("Font Picker") {
            ContentView()
        }
    }
}
