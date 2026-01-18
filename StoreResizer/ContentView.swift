import SwiftUI
import UniformTypeIdentifiers
import AppKit

// MARK: - Size Presets
import SwiftUI

enum SizePreset: String, CaseIterable {
    case custom = "Custom"
    
    // MARK: - iPhone (App Store Connect)
    // 6.9" Display (iPhone 16 Pro Max)
    case iPhone_6_9 = "iPhone 6.9\" Display (1320x2868)"
    // 6.7" Display (iPhone 15 Pro Max, 14 Pro Max) - Very common
    case iPhone_6_7 = "iPhone 6.7\" Display (1290x2796)"
    // 6.5" Display (iPhone 11 Pro Max, XS Max) - Standard Max size
    case iPhone_6_5 = "iPhone 6.5\" Display (1242x2688)"
    // 6.1" Display (iPhone 15 Pro, 14 Pro) - Standard Pro size
    case iPhone_6_1 = "iPhone 6.1\" Display (1179x2556)"
    // 5.5" Display (iPhone 8 Plus) - Legacy support
    case iPhone_5_5 = "iPhone 5.5\" Display (1242x2208)"
    // 4.7" Display (iPhone SE 3rd Gen)
    case iPhone_4_7 = "iPhone 4.7\" Display (750x1334)"
    
    // MARK: - iPad
    // 13" Ultra Retina XDR (iPad Pro M4)
    case iPad_13 = "iPad Pro 13\" (2064x2752)"
    // 12.9" Liquid Retina XDR (iPad Pro 12.9 2nd-6th Gen)
    case iPad_12_9 = "iPad Pro 12.9\" (2048x2732)"
    // 11" Ultra Retina XDR (iPad Pro 11 M4)
    case iPad_11 = "iPad Pro 11\" (1668x2420)"
    
    // MARK: - Mac
    case Mac_AppStore = "Mac App Store (2880x1800)"
    
    // MARK: - Google Play
    case Android_Phone = "Google Play Phone (1080x1920)"
    case Android_Tablet_10 = "Google Play Tablet 10\" (1920x1200)"
    
    // MARK: - Marketing Assets (Essential)
    case PlayStore_Feature = "Google Play Feature Graphic (1024x500)"
    case AppStore_Icon = "App Store Icon (1024x1024)"
    case PlayStore_Icon = "Google Play Icon (512x512)"
    
    // MARK: - Wearables
    case Apple_Watch = "Apple Watch Ultra (502x410)"

    var size: CGSize {
        switch self {
        case .custom: return CGSize(width: 1242, height: 2688)
            
        case .iPhone_6_9: return CGSize(width: 1320, height: 2868)
        case .iPhone_6_7: return CGSize(width: 1290, height: 2796)
        case .iPhone_6_5: return CGSize(width: 1242, height: 2688)
        case .iPhone_6_1: return CGSize(width: 1179, height: 2556)
        case .iPhone_5_5: return CGSize(width: 1242, height: 2208)
        case .iPhone_4_7: return CGSize(width: 750, height: 1334)
            
        case .iPad_13: return CGSize(width: 2064, height: 2752)
        case .iPad_12_9: return CGSize(width: 2048, height: 2732)
        case .iPad_11: return CGSize(width: 1668, height: 2420)
            
        case .Mac_AppStore: return CGSize(width: 2880, height: 1800)
            
        case .Android_Phone: return CGSize(width: 1080, height: 1920)
        case .Android_Tablet_10: return CGSize(width: 1920, height: 1200)
            
        case .PlayStore_Feature: return CGSize(width: 1024, height: 500)
        case .AppStore_Icon: return CGSize(width: 1024, height: 1024)
        case .PlayStore_Icon: return CGSize(width: 512, height: 512)
            
        case .Apple_Watch: return CGSize(width: 502, height: 410)
        }
    }
}

// MARK: - Output Format
enum OutputFormat: String, CaseIterable {
    case png = "PNG"
    case jpeg = "JPEG"
    case tiff = "TIFF"

    var fileType: NSBitmapImageRep.FileType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .tiff: return .tiff
        }
    }

    var utType: UTType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .tiff: return .tiff
        }
    }
}

// MARK: - Image Resizing Extension
extension NSImage {
    func resized(to targetedSize: CGSize) -> NSImage? {
        let width = Int(targetedSize.width)
        let height = Int(targetedSize.height)

        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        bitmapRep.size = targetedSize

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.current?.imageInterpolation = .high

        self.draw(in: NSRect(x: 0, y: 0, width: targetedSize.width, height: targetedSize.height),
                  from: NSRect(origin: .zero, size: self.size),
                  operation: .copy,
                  fraction: 1.0)

        NSGraphicsContext.restoreGraphicsState()

        let newImage = NSImage(size: targetedSize)
        newImage.addRepresentation(bitmapRep)

        return newImage
    }

    func compressedData(format: OutputFormat, quality: Double) -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }

        var properties: [NSBitmapImageRep.PropertyKey: Any] = [:]
        if format == .jpeg {
            properties[.compressionFactor] = quality
        }

        return bitmap.representation(using: format.fileType, properties: properties)
    }
}

// MARK: - Image Info Wrapper
struct ImageInfo: Identifiable {
    let id = UUID()
    let image: NSImage
    let originalName: String
    let originalSize: CGSize
    let originalFileSize: Int64?
    var processedData: Data?
    var processedFormat: OutputFormat = .png

    var originalDimensions: String { "\(Int(originalSize.width)) x \(Int(originalSize.height))" }
    var originalFileSizeString: String {
        guard let size = originalFileSize else { return "Unknown" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    var processedFileSizeString: String {
        guard let data = processedData else { return "-" }
        return ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
    }
}

// MARK: - Single Image Wrapper for Drag
struct ProcessedImage: Identifiable, Transferable {
    let id = UUID()
    let image: NSImage
    let originalName: String
    let format: OutputFormat
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .png) { processedImg in
            let baseName = (processedImg.originalName as NSString).deletingPathExtension
            let ext = processedImg.format.rawValue.lowercased()
            let fileName = "\(baseName)_resized.\(ext)"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

            try? processedImg.data.write(to: tempURL)

            return SentTransferredFile(tempURL)
        }
    }
}

// MARK: - Batch Wrapper
struct BatchResult: Transferable {
    let images: [ProcessedImage]

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .folder) { batch in
            let folderName = "Resized_Batch_\(Int(Date().timeIntervalSince1970))"
            let folderURL = FileManager.default.temporaryDirectory.appendingPathComponent(folderName)

            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

            for (index, item) in batch.images.enumerated() {
                let baseName = (item.originalName as NSString).deletingPathExtension
                let ext = item.format.rawValue.lowercased()
                let uniqueFileName = "\(baseName)_resized_\(index).\(ext)"
                let fileURL = folderURL.appendingPathComponent(uniqueFileName)

                try? item.data.write(to: fileURL)
            }

            return SentTransferredFile(folderURL)
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Binding var outputFormat: OutputFormat
    @Binding var jpegQuality: Double
    @Binding var maintainAspectRatio: Bool
    @Binding var selectedPreset: SizePreset
    @Binding var targetWidth: String
    @Binding var targetHeight: String
    @Binding var showSuffixEditor: Bool
    @Binding var outputSuffix: String

    @State private var showPresetsPopover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Preset Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Size Preset")
                    .font(.headline)
                    .foregroundColor(.primary)

                Menu {
                    ForEach(SizePreset.allCases, id: \.self) { preset in
                        Button(preset.rawValue) {
                            selectedPreset = preset
                            if preset != .custom {
                                targetWidth = String(Int(preset.size.width))
                                targetHeight = String(Int(preset.size.height))
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedPreset.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                }
                .menuStyle(.borderlessButton)
            }

            // Dimensions Input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Dimensions")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Toggle("Lock Aspect Ratio", isOn: $maintainAspectRatio)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        TextField("Width", text: $targetWidth)
                            .frame(width: 100)
                            .textFieldStyle(.roundedBorder)
                        Text("px")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }

                    Text("×")
                        .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                        TextField("Height", text: $targetHeight)
                            .frame(width: 100)
                            .textFieldStyle(.roundedBorder)
                        Text("px")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }

                    Spacer()

                    Button(action: swapDimensions) {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                    .buttonStyle(.borderless)
                    .help("Swap dimensions")
                }
            }

            Divider()

            // Output Format
            VStack(alignment: .leading, spacing: 8) {
                Text("Output Format")
                    .font(.headline)
                    .foregroundColor(.primary)

                Picker("", selection: $outputFormat) {
                    ForEach(OutputFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Quality Slider (JPEG only)
            if outputFormat == .jpeg {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Quality")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(Int(jpegQuality * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }

                    Slider(value: $jpegQuality, in: 0.1...1.0, step: 0.05)
                        .controlSize(.small)

                    HStack {
                        Text("Lower file size")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Higher quality")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Output Suffix
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Filename Suffix")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: { showSuffixEditor.toggle() }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }

                if showSuffixEditor {
                    TextField("Enter suffix", text: $outputSuffix)
                        .textFieldStyle(.roundedBorder)
                        .help("Text to append before file extension")
                } else {
                    Text("_resized\(outputSuffix)")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(4)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func swapDimensions() {
        let temp = targetWidth
        targetWidth = targetHeight
        targetHeight = temp
    }
}

// MARK: - Image Thumbnail View
struct ImageThumbnailView: View {
    let info: ImageInfo
    let onDelete: () -> Void

    @State private var isHovering = false
    @State private var showPreview = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            // Delete button
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .help("Remove image")
            }

            ZStack(alignment: .bottomLeading) {
                Image(nsImage: info.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHovering ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                    .onTapGesture(count: 2) {
                        showPreview = true
                    }

                // Dimensions badge
                Text(info.originalDimensions)
                    .font(.system(size: 8))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
            .contextMenu {
                Button("Show in Finder") {
                    // Could implement Finder integration
                }
                Button("Remove", role: .destructive) {
                    onDelete()
                }
            }
        }
        .frame(width: 80, height: 100)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
        .sheet(isPresented: $showPreview) {
            ImagePreviewSheet(image: info.image, info: info)
        }
    }
}

// MARK: - Image Preview Sheet
struct ImagePreviewSheet: View {
    let image: NSImage
    let info: ImageInfo
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(info.originalName)
                .font(.headline)

            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 500, maxHeight: 500)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Dimensions:")
                        .foregroundColor(.secondary)
                    Text(info.originalDimensions)
                        .foregroundColor(.primary)
                }

                HStack {
                    Text("File Size:")
                        .foregroundColor(.secondary)
                    Text(info.originalFileSizeString)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            Button("Close") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        .frame(width: 550, height: 650)
    }
}

// MARK: - Progress Overlay
struct ProgressOverlay: View {
    let current: Int
    let total: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Processing \(current) of \(total)")
                    .foregroundColor(.white)
                    .font(.headline)

                Text("Please wait...")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.caption)
            }
            .padding(24)
            .background(Color(nsColor: .windowBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 20)
        }
    }
}

// MARK: - Main View
struct ContentView: View {
    @State private var targetWidth: String = "1242"
    @State private var targetHeight: String = "2688"

    @State private var inputImages: [ImageInfo] = []
    @State private var outputImages: [ProcessedImage] = []
    @State private var isHoveringDropZone = false

    // Settings
    @State private var selectedPreset: SizePreset = .iPhone_6_5
    @State private var outputFormat: OutputFormat = .png
    @State private var jpegQuality: Double = 0.85
    @State private var maintainAspectRatio: Bool = true
    @State private var outputSuffix: String = ""
    @State private var showSuffixEditor: Bool = false

    // Processing state
    @State private var isProcessing = false
    @State private var processingProgress: Int = 0
    @State private var showSettings = true

    var body: some View {
        HSplitView {
            // Left Side - Settings & Input
            VStack(spacing: 0) {
                // Settings Panel
                SettingsView(
                    outputFormat: $outputFormat,
                    jpegQuality: $jpegQuality,
                    maintainAspectRatio: $maintainAspectRatio,
                    selectedPreset: $selectedPreset,
                    targetWidth: $targetWidth,
                    targetHeight: $targetHeight,
                    showSuffixEditor: $showSuffixEditor,
                    outputSuffix: $outputSuffix
                )

                Divider()

                // Input Drop Zone
                VStack(spacing: 12) {
                    Text("Drop Images Here")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 36))
                        .foregroundColor(isHoveringDropZone ? .accentColor : .secondary)
                        .scaleEffect(isHoveringDropZone ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHoveringDropZone)

                    Text("\(inputImages.count) image\(inputImages.count == 1 ? "" : "s") ready")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isHoveringDropZone ? Color.accentColor : Color.clear,
                            lineWidth: 2
                        )
                )
                .padding()
                .onDrop(of: [.image], isTargeted: $isHoveringDropZone) { providers in
                    loadIncomingImages(from: providers)
                    return true
                }
                .onTapGesture(count: 2) {
                    openFilePanel()
                }
                .help("Double-click to browse files")

                // Process Button
                VStack(spacing: 8) {
                    Button(action: processImages) {
                        HStack {
                            Image(systemName: isProcessing ? "gear" : "play.fill")
                                .rotationEffect(.degrees(isProcessing ? 360 : 0))
                                .animation(isProcessing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isProcessing)
                            Text(isProcessing ? "Processing..." : "Process Images")
                            if !isProcessing && inputImages.count > 0 {
                                Text("(\(inputImages.count))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(inputImages.isEmpty || isProcessing)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    HStack(spacing: 16) {
                        Button("Clear All") {
                            inputImages.removeAll()
                            outputImages.removeAll()
                        }
                        .disabled(inputImages.isEmpty || isProcessing)

                        Button("Browse...") {
                            openFilePanel()
                        }
                        .disabled(isProcessing)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.bottom, 16)
            }
            .frame(minWidth: 300, maxWidth: 400)

            // Right Side - Output
            VStack(spacing: 0) {
                // Output Header
                HStack {
                    Text("Results")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    if !outputImages.isEmpty {
                        Text("\(outputImages.count) image\(outputImages.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        // Drag All Button
                        VStack(spacing: 2) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 20))
                            Text("Drag All")
                                .font(.system(size: 9))
                        }
                        .padding(6)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                        .shadow(radius: 2)
                        .draggable(BatchResult(images: outputImages))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()

                // Output Grid
                ScrollView {
                    if outputImages.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.stack")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No processed images yet")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Text("Drop images on the left and click Process")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                            ForEach(outputImages) { processed in
                                VStack(alignment: .trailing, spacing: 4) {
                                    ZStack {
                                        Image(nsImage: processed.image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 90, height: 90)
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                            )

                                        // Format badge
                                        VStack {
                                            HStack {
                                                Text(processed.format.rawValue)
                                                    .font(.system(size: 8, weight: .bold))
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 2)
                                                    .background(Color.accentColor)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(4)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                        .padding(4)
                                    }
                                }
                                .frame(width: 100, height: 100)
                                .draggable(processed)
                                .help("Drag to export")
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .frame(minWidth: 300)
        }
        .frame(minWidth: 700, minHeight: 500)
        .overlay(progressOverlay)
    }

    private var progressOverlay: some View {
        Group {
            if isProcessing {
                ProgressOverlay(current: processingProgress, total: inputImages.count)
            }
        }
    }

    // MARK: - Load Images
    private func loadIncomingImages(from providers: [NSItemProvider]) {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSImage.self) {
                let fileName = provider.suggestedName ?? "image"

                provider.loadObject(ofClass: NSImage.self) { image, error in
                    guard let nsImage = image as? NSImage else { return }

                    // File size not available from drag-drop in this version
                    let fileSize: Int64? = nil

                    DispatchQueue.main.async {
                        let info = ImageInfo(
                            image: nsImage,
                            originalName: fileName,
                            originalSize: nsImage.size,
                            originalFileSize: fileSize
                        )
                        inputImages.append(info)
                    }
                }
            }
        }
    }

    // MARK: - Open File Panel
    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            for url in panel.urls {
                if let image = NSImage(contentsOf: url) {
                    let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                    let fileSize = attrs?[.size] as? Int64

                    let info = ImageInfo(
                        image: image,
                        originalName: url.deletingPathExtension().lastPathComponent,
                        originalSize: image.size,
                        originalFileSize: fileSize
                    )
                    inputImages.append(info)
                }
            }
        }
    }

    // MARK: - Process Images
    private func processImages() {
        guard let w = Double(targetWidth), let h = Double(targetHeight),
              w > 0, h > 0 else { return }

        isProcessing = true
        outputImages.removeAll()
        processingProgress = 0

        // Process on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            var processed: [ProcessedImage] = []

            for (index, input) in self.inputImages.enumerated() {
                if let resizedImage = input.image.resized(to: CGSize(width: w, height: h)) {
                    if let data = resizedImage.compressedData(format: self.outputFormat, quality: self.jpegQuality) {
                        let processedImage = ProcessedImage(
                            image: resizedImage,
                            originalName: input.originalName,
                            format: self.outputFormat,
                            data: data
                        )
                        processed.append(processedImage)
                    }

                    DispatchQueue.main.async {
                        self.processingProgress = index + 1
                    }
                }
            }

            DispatchQueue.main.async {
                self.outputImages = processed
                self.inputImages.removeAll()
                self.isProcessing = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
