import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct FontItem: Identifiable, Hashable {
    let id: String
    let name: String
    let family: String
}

struct PDFSampleSheetGenerator {
    static func generatePDF(
        sampleText: String,
        fontSize: Double,
        fonts: [FontItem],
        favoriteFontIDs: Set<String>,
        documentName: String?
    ) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let marginX: CGFloat = 46
        let contentWidth = pageWidth - (marginX * 2)
        let marginTop: CGFloat = 46
        let marginBottom: CGFloat = 44
        
        let sampleSize = max(16, min(CGFloat(fontSize), 34))
        let displayText = sampleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "The quick brown fox jumps over the lazy dog" : sampleText
        
        struct MeasuredItem {
            let item: FontItem
            let isPinned: Bool
            let labelHeight: CGFloat
            let previewHeight: CGFloat
            let totalHeight: CGFloat
        }
        
        var measuredItems: [MeasuredItem] = []
        for item in fonts {
            let font = NSFont(name: item.name, size: sampleSize) ??
                       NSFont(name: item.family, size: sampleSize) ??
                       NSFont.systemFont(ofSize: sampleSize)
            
            let previewRect = (displayText as NSString).boundingRect(
                with: CGSize(width: contentWidth, height: 250),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font]
            )
            let labelHeight: CGFloat = 16
            let previewHeight = max(ceil(previewRect.height), sampleSize + 4)
            let totalHeight = labelHeight + 3 + previewHeight + 14
            
            measuredItems.append(MeasuredItem(
                item: item,
                isPinned: favoriteFontIDs.contains(item.id),
                labelHeight: labelHeight,
                previewHeight: previewHeight,
                totalHeight: totalHeight
            ))
        }
        
        let firstPageHeaderHeight: CGFloat = 86
        let subsequentPageHeaderHeight: CGFloat = 34
        let footerHeight: CGFloat = 24
        
        var pages: [[MeasuredItem]] = []
        var currentPageItems: [MeasuredItem] = []
        var currentY: CGFloat = firstPageHeaderHeight
        let maxPageY = pageHeight - marginBottom - footerHeight
        
        for item in measuredItems {
            if currentY + item.totalHeight > maxPageY && !currentPageItems.isEmpty {
                pages.append(currentPageItems)
                currentPageItems = []
                currentY = subsequentPageHeaderHeight
            }
            currentPageItems.append(item)
            currentY += item.totalHeight
        }
        if !currentPageItems.isEmpty || pages.isEmpty {
            pages.append(currentPageItems)
        }
        
        let totalPages = max(1, pages.count)
        
        let pdfData = NSMutableData()
        let consumer = CGDataConsumer(data: pdfData as CFMutableData)!
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: Date())
        
        // Fixed print colors (independent of macOS Dark/Light Mode)
        let printTextPrimary = NSColor(srgbRed: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)
        let printTextSecondary = NSColor(srgbRed: 0.42, green: 0.42, blue: 0.44, alpha: 1.0)
        let printLineColor = NSColor(srgbRed: 0.85, green: 0.85, blue: 0.87, alpha: 1.0)
        let printPinnedColor = NSColor(srgbRed: 0.88, green: 0.45, blue: 0.05, alpha: 1.0)
        let printPageBackground = NSColor.white
        
        func pdfY(_ topDownY: CGFloat) -> CGFloat {
            return pageHeight - topDownY
        }
        
        for (pageIndex, pageItems) in pages.enumerated() {
            let pageNum = pageIndex + 1
            context.beginPDFPage(nil)
            
            // Explicitly paint page canvas white
            context.setFillColor(printPageBackground.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
            
            let gc = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.current = gc
            
            var yPos: CGFloat = marginTop
            
            if pageNum == 1 {
                let title = "PickFonts Specimen Sheet" as NSString
                title.draw(
                    at: CGPoint(x: marginX, y: pdfY(yPos + 22)),
                    withAttributes: [
                        .font: NSFont.boldSystemFont(ofSize: 20),
                        .foregroundColor: printTextPrimary
                    ]
                )
                
                let docLabel = documentName != nil ? "\(documentName!) • " : ""
                let metaText = "\(docLabel)\(fonts.count) fonts • \(dateString)" as NSString
                metaText.draw(
                    at: CGPoint(x: marginX, y: pdfY(yPos + 38)),
                    withAttributes: [
                        .font: NSFont.systemFont(ofSize: 9.5),
                        .foregroundColor: printTextSecondary
                    ]
                )
                
                let phraseLabel = "Phrase: \"\(displayText)\"" as NSString
                phraseLabel.draw(
                    in: CGRect(x: marginX, y: pdfY(yPos + 60), width: contentWidth, height: 18),
                    withAttributes: [
                        .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                        .foregroundColor: printTextPrimary
                    ]
                )
                
                context.setStrokeColor(printLineColor.cgColor)
                context.setLineWidth(0.75)
                context.move(to: CGPoint(x: marginX, y: pdfY(yPos + 68)))
                context.addLine(to: CGPoint(x: marginX + contentWidth, y: pdfY(yPos + 68)))
                context.strokePath()
                
                yPos += firstPageHeaderHeight
            } else {
                let prefixCount = min(40, displayText.count)
                let prefixStr = String(displayText.prefix(prefixCount))
                let headerText = "PickFonts Specimen Sheet — \"\(prefixStr)\(displayText.count > 40 ? "..." : "")\"" as NSString
                headerText.draw(
                    at: CGPoint(x: marginX, y: pdfY(yPos + 12)),
                    withAttributes: [
                        .font: NSFont.systemFont(ofSize: 9),
                        .foregroundColor: printTextSecondary
                    ]
                )
                
                context.setStrokeColor(printLineColor.cgColor)
                context.setLineWidth(0.5)
                context.move(to: CGPoint(x: marginX, y: pdfY(yPos + 18)))
                context.addLine(to: CGPoint(x: marginX + contentWidth, y: pdfY(yPos + 18)))
                context.strokePath()
                
                yPos += subsequentPageHeaderHeight
            }
            
            for measured in pageItems {
                let item = measured.item
                
                var familyTitle = item.family
                if measured.isPinned {
                    familyTitle += "  [PINNED]"
                }
                
                let labelAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 9.5),
                    .foregroundColor: measured.isPinned ? printPinnedColor : printTextSecondary
                ]
                (familyTitle as NSString).draw(
                    at: CGPoint(x: marginX, y: pdfY(yPos + 11)),
                    withAttributes: labelAttrs
                )
                
                let itemFont = NSFont(name: item.name, size: sampleSize) ??
                               NSFont(name: item.family, size: sampleSize) ??
                               NSFont.systemFont(ofSize: sampleSize)
                
                let previewAttrs: [NSAttributedString.Key: Any] = [
                    .font: itemFont,
                    .foregroundColor: printTextPrimary
                ]
                
                let textRect = CGRect(
                    x: marginX,
                    y: pdfY(yPos + 14 + measured.previewHeight),
                    width: contentWidth,
                    height: measured.previewHeight
                )
                
                (displayText as NSString).draw(
                    in: textRect,
                    withAttributes: previewAttrs
                )
                
                let divY = pdfY(yPos + measured.totalHeight - 3)
                context.setStrokeColor(printLineColor.cgColor)
                context.setLineWidth(0.5)
                context.move(to: CGPoint(x: marginX, y: divY))
                context.addLine(to: CGPoint(x: marginX + contentWidth, y: divY))
                context.strokePath()
                
                yPos += measured.totalHeight
            }
            
            let footerPageText = "Page \(pageNum) of \(totalPages)" as NSString
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 8.5),
                .foregroundColor: printTextSecondary
            ]
            let pageTextSize = footerPageText.size(withAttributes: footerAttrs)
            footerPageText.draw(
                at: CGPoint(x: marginX + contentWidth - pageTextSize.width, y: marginBottom - 14),
                withAttributes: footerAttrs
            )
            
            let brandingText = "PickFonts for macOS" as NSString
            brandingText.draw(
                at: CGPoint(x: marginX, y: marginBottom - 14),
                withAttributes: footerAttrs
            )
            
            context.endPDFPage()
        }
        
        context.closePDF()
        return pdfData as Data
    }
}

final class FontPickerViewModel: ObservableObject {
    @Published var sampleText: String = "The quick brown fox jumps over the lazy dog"
    @Published var fontSize: Double = 28.0
    @Published var searchQuery: String = ""
    @Published var removedFontIDs: Set<String> = []
    @Published var favoriteFontIDs: Set<String> = []
    @Published var showFavoritesOnly: Bool = false
    @Published var currentFileURL: URL? = nil
    @Published var statusMessage: String? = nil
    
    let allFonts: [FontItem]
    private let favoritesStorageKey = "PickFonts_FavoriteFontIDs"
    private var statusDismissTask: DispatchWorkItem?
    
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
            currentFileURL = nil
        }
        postStatus("Restored all fonts")
    }
    
    func copyFontNames() {
        let text = visibleFonts.map { $0.family }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        postStatus("Copied \(visibleFonts.count) font names to clipboard")
    }
    
    func copyPinnedFontNames() {
        let text = pinnedFonts.map { $0.family }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        postStatus("Copied \(pinnedFonts.count) pinned font names to clipboard")
    }
    
    func postStatus(_ msg: String) {
        statusDismissTask?.cancel()
        statusMessage = msg
        let task = DispatchWorkItem { [weak self] in
            withAnimation {
                self?.statusMessage = nil
            }
        }
        statusDismissTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: task)
    }
    
    // MARK: - .flxml Open / Save Support
    
    func openFile() {
        let panel = NSOpenPanel()
        panel.title = "Open Font List"
        panel.message = "Select a .flxml Font List file"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if let flxmlType = UTType(filenameExtension: "flxml") {
            panel.allowedContentTypes = [flxmlType, .xml]
        } else {
            panel.allowedContentTypes = [.xml]
        }
        
        if panel.runModal() == .OK, let url = panel.url {
            loadFromFile(url: url)
        }
    }
    
    func saveFile() {
        if let url = currentFileURL {
            saveToFile(url: url)
        } else {
            saveFileAs()
        }
    }
    
    func saveFileAs() {
        let panel = NSSavePanel()
        panel.title = "Save Font List"
        panel.message = "Choose a location to save your font list (.flxml)"
        panel.nameFieldStringValue = currentFileURL?.lastPathComponent ?? "MyFontList.flxml"
        if let flxmlType = UTType(filenameExtension: "flxml") {
            panel.allowedContentTypes = [flxmlType, .xml]
        } else {
            panel.allowedContentTypes = [.xml]
        }
        panel.isExtensionHidden = false
        
        if panel.runModal() == .OK, let url = panel.url {
            saveToFile(url: url)
        }
    }
    
    func saveToFile(url: URL) {
        do {
            let root = XMLElement(name: "FontList")
            let sampleAttr = XMLNode.attribute(withName: "SampleText", stringValue: sampleText) as! XMLNode
            root.addAttribute(sampleAttr)
            
            let fontsElement = XMLElement(name: "Fonts")
            for font in visibleFonts {
                let fontNode = XMLElement(name: "Font", stringValue: font.family)
                fontsElement.addChild(fontNode)
            }
            root.addChild(fontsElement)
            
            let doc = XMLDocument(rootElement: root)
            doc.version = "1.0"
            doc.characterEncoding = "UTF-8"
            
            let xmlData = doc.xmlData(options: [.nodePrettyPrint])
            try xmlData.write(to: url, options: .atomic)
            
            self.currentFileURL = url
            postStatus("Saved \(visibleFonts.count) fonts to \(url.lastPathComponent)")
        } catch {
            postStatus("Save failed: \(error.localizedDescription)")
        }
    }
    
    func loadFromFile(url: URL) {
        do {
            let doc = try XMLDocument(contentsOf: url, options: [])
            guard let root = doc.rootElement(), root.name == "FontList" else {
                postStatus("Error: Not a valid FontList XML file.")
                return
            }
            
            var loadedSample = root.attribute(forName: "SampleText")?.stringValue
            if loadedSample == nil {
                loadedSample = root.elements(forName: "SampleText").first?.stringValue
            }
            
            let fontNodes = try doc.nodes(forXPath: "//FontList/Fonts/Font")
            var fileFontNames: [String] = []
            for node in fontNodes {
                if let val = node.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !val.isEmpty {
                    fileFontNames.append(val)
                }
            }
            
            let matchingIDs = Set(allFonts.filter { font in
                fileFontNames.contains { name in
                    font.family.localizedCaseInsensitiveCompare(name) == .orderedSame ||
                    font.name.localizedCaseInsensitiveCompare(name) == .orderedSame
                }
            }.map { $0.id })
            
            let missingNames = fileFontNames.filter { name in
                !allFonts.contains { font in
                    font.family.localizedCaseInsensitiveCompare(name) == .orderedSame ||
                    font.name.localizedCaseInsensitiveCompare(name) == .orderedSame
                }
            }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                if let phrase = loadedSample, !phrase.isEmpty {
                    self.sampleText = phrase
                }
                self.removedFontIDs = Set(allFonts.map { $0.id }).subtracting(matchingIDs)
                self.searchQuery = ""
                self.showFavoritesOnly = false
                self.currentFileURL = url
            }
            
            if missingNames.isEmpty {
                postStatus("Loaded \(matchingIDs.count) fonts from \(url.lastPathComponent)")
            } else {
                postStatus("Loaded \(matchingIDs.count)/\(fileFontNames.count) fonts (\(missingNames.count) not installed)")
            }
        } catch {
            postStatus("Failed to open file: \(error.localizedDescription)")
        }
    }
    
    func exportSampleSheetPDF() {
        let panel = NSSavePanel()
        panel.title = "Save Sample Sheet to PDF"
        panel.message = "Choose a destination for your PDF font sample sheet"
        let baseName = currentFileURL?.deletingPathExtension().lastPathComponent ?? "Font_Sample_Sheet"
        panel.nameFieldStringValue = "\(baseName).pdf"
        panel.allowedContentTypes = [.pdf]
        panel.isExtensionHidden = false
        
        if panel.runModal() == .OK, let url = panel.url {
            let pdfData = PDFSampleSheetGenerator.generatePDF(
                sampleText: sampleText,
                fontSize: fontSize,
                fonts: visibleFonts,
                favoriteFontIDs: favoriteFontIDs,
                documentName: currentFileURL?.lastPathComponent
            )
            do {
                try pdfData.write(to: url, options: .atomic)
                postStatus("Saved PDF sample sheet to \(url.lastPathComponent)")
                NSWorkspace.shared.open(url)
            } catch {
                postStatus("PDF export failed: \(error.localizedDescription)")
            }
        }
    }
}

struct ContentView: View {
    @ObservedObject var vm: FontPickerViewModel
    
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
                        .frame(maxWidth: 180)
                    
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
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.summaryCountText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let status = vm.statusMessage {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(.accentColor)
                                .transition(.opacity)
                        }
                    }
                    
                    Spacer()
                    
                    // File Actions Menu
                    Menu {
                        Button(action: { vm.openFile() }) {
                            Label("Open Font List (.flxml)...", systemImage: "doc.badge.plus")
                        }
                        
                        Divider()
                        
                        Button(action: { vm.saveFile() }) {
                            Label("Save Font List", systemImage: "square.and.arrow.down")
                        }
                        
                        Button(action: { vm.saveFileAs() }) {
                            Label("Save Font List As...", systemImage: "square.and.arrow.down.on.square")
                        }
                        
                        Divider()
                        
                        Button(action: { vm.exportSampleSheetPDF() }) {
                            Label("Save Sample Sheet to PDF...", systemImage: "arrow.down.doc")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                            Text(vm.currentFileURL != nil ? vm.currentFileURL!.deletingPathExtension().lastPathComponent : "Font List")
                                .lineLimit(1)
                        }
                    }
                    .menuStyle(.borderedButton)
                    .help("Open or Save Font List files (.flxml)")
                    
                    Button(action: { vm.exportSampleSheetPDF() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.doc")
                            Text("PDF")
                        }
                    }
                    .buttonStyle(.bordered)
                    .help("Save sample sheet to PDF (⌘P)")
                    
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
                    .disabled(vm.removedFontIDs.isEmpty && vm.currentFileURL == nil)
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
        .frame(minWidth: 720, minHeight: 520)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url, url.pathExtension.lowercased() == "flxml" {
                    DispatchQueue.main.async {
                        vm.loadFromFile(url: url)
                    }
                }
            }
            return true
        }
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
    @StateObject private var vm = FontPickerViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView(vm: vm)
                .navigationTitle(vm.currentFileURL != nil ? "\(vm.currentFileURL!.deletingPathExtension().lastPathComponent) — PickFonts" : "PickFonts")
                .onOpenURL { url in
                    vm.loadFromFile(url: url)
                }
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Open Font List...") {
                    vm.openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .saveItem) {
                Button("Save Font List") {
                    vm.saveFile()
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Save Font List As...") {
                    vm.saveFileAs()
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])
            }
            CommandGroup(after: .saveItem) {
                Divider()
                Button("Save Sample Sheet to PDF...") {
                    vm.exportSampleSheetPDF()
                }
                .keyboardShortcut("p", modifiers: .command)
            }
        }
    }
}
