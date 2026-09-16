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
    @Published var favoriteFontIDs: Set<String> = []
    @Published var showFavoritesOnly: Bool = false
    
    let allFonts: [FontItem]
    private let favoritesStorageKey = "PickFonts_FavoriteFontIDs"
    
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
        
        if let savedFavorites = UserDefaults.standard.array(forKey: favoritesStorageKey) as? [String] {
            self.favoriteFontIDs = Set(savedFavorites)
        }
    }
    
    var visibleFonts: [FontItem] {
        allFonts.filter { item in
            !removedFontIDs.contains(item.id) &&
            (!showFavoritesOnly || favoriteFontIDs.contains(item.id)) &&
            (searchQuery.isEmpty || item.family.localizedCaseInsensitiveContains(searchQuery))
        }
    }
    
    var pinnedFonts: [FontItem] {
        visibleFonts.filter { favoriteFontIDs.contains($0.id) }
    }
    
    var unpinnedFonts: [FontItem] {
        visibleFonts.filter { !favoriteFontIDs.contains($0.id) }
    }
    
    var summaryCountText: String {
        if showFavoritesOnly {
            return "Showing \(visibleFonts.count) pinned font\(visibleFonts.count == 1 ? "" : "s")"
        }
        return "Showing \(visibleFonts.count) of \(allFonts.count) fonts"
    }
    
    var availableLetters: Set<Character> {
        Set(visibleFonts.compactMap { $0.family.uppercased().first }.filter { $0.isLetter })
    }
    
    func isFavorite(_ item: FontItem) -> Bool {
        favoriteFontIDs.contains(item.id)
    }
    
    func toggleFavorite(_ item: FontItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if favoriteFontIDs.contains(item.id) {
                favoriteFontIDs.remove(item.id)
            } else {
                favoriteFontIDs.insert(item.id)
            }
            UserDefaults.standard.set(Array(favoriteFontIDs), forKey: favoritesStorageKey)
        }
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
    
    func copyPinnedFontNames() {
        let text = pinnedFonts.map { $0.family }.joined(separator: "\n")
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
                
                HStack(spacing: 10) {
                    TextField("Filter by name...", text: $vm.searchQuery)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                    
                    Button(action: {
                        withAnimation {
                            vm.showFavoritesOnly.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: vm.showFavoritesOnly ? "pin.fill" : "pin")
                                .foregroundColor(vm.showFavoritesOnly ? .orange : .secondary)
                            Text(vm.favoriteFontIDs.isEmpty ? "Favorites" : "Favorites (\(vm.favoriteFontIDs.count))")
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Text(vm.summaryCountText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if !vm.pinnedFonts.isEmpty && !vm.showFavoritesOnly {
                        Button("Copy Pinned (\(vm.pinnedFonts.count))") {
                            vm.copyPinnedFontNames()
                        }
                    }
                    
                    Button("Copy Names") {
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
                        if vm.showFavoritesOnly {
                            if vm.visibleFonts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "pin.slash")
                                        .font(.system(size: 36))
                                        .foregroundColor(.secondary)
                                    Text(vm.favoriteFontIDs.isEmpty ? "No pinned fonts yet" : "No matching pinned fonts")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    Text(vm.favoriteFontIDs.isEmpty ? "Click the pin icon on any font to save it to your favorites." : "Try clearing your search query.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary.opacity(0.8))
                                }
                                .frame(maxWidth: .infinity, minHeight: 250)
                                .padding()
                            } else {
                                ForEach(vm.visibleFonts) { item in
                                    fontRow(item)
                                }
                            }
                        } else if !vm.pinnedFonts.isEmpty {
                            sectionHeader(title: "PINNED", icon: "pin.fill", count: vm.pinnedFonts.count)
                            ForEach(vm.pinnedFonts) { item in
                                fontRow(item)
                            }
                            
                            sectionHeader(title: "ALL FONTS", count: vm.unpinnedFonts.count)
                            ForEach(vm.unpinnedFonts) { item in
                                fontRow(item)
                            }
                        } else {
                            ForEach(vm.visibleFonts) { item in
                                fontRow(item)
                            }
                        }
                    }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 520)
    }
    
    @ViewBuilder
    private func fontRow(_ item: FontItem) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: { vm.toggleFavorite(item) }) {
                Image(systemName: vm.isFavorite(item) ? "pin.fill" : "pin")
                    .font(.system(size: 13))
                    .foregroundColor(vm.isFavorite(item) ? .orange : .secondary)
            }
            .buttonStyle(.plain)
            .help(vm.isFavorite(item) ? "Unpin font" : "Pin font to top")
            
            Button(action: { vm.removeFont(item) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Dismiss font")
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.family)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    if vm.isFavorite(item) {
                        Text("PINNED")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(3)
                    }
                }
                
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
    
    @ViewBuilder
    private func sectionHeader(title: String, icon: String? = nil, count: Int) -> some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(.orange)
            }
            Text("\(title) (\(count))")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.85))
        
        Divider()
    }
}

@main
struct PickFontsApp: App {
    var body: some Scene {
        WindowGroup("PickFonts") {
            ContentView()
        }
    }
}
