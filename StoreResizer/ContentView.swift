import SwiftUI
import UniformTypeIdentifiers
import AppKit

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
}

// MARK: - Single Image Wrapper
struct ProcessedImage: Identifiable, Transferable {
    let id = UUID()
    let image: NSImage
    let originalName: String
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .png) { processedImg in
            let baseName = (processedImg.originalName as NSString).deletingPathExtension
            let fileName = "\(baseName)_resized.png"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            if let tiffData = processedImg.image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                try pngData.write(to: tempURL)
            }
            
            return SentTransferredFile(tempURL)
        }
    }
}

// MARK: - Batch Wrapper (Fixed)
struct BatchResult: Transferable {
    let images: [ProcessedImage]
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .folder) { batch in
            // 1. Create a unique folder for this specific drag event
            let folderName = "Resized_Batch_\(Int(Date().timeIntervalSince1970))"
            let folderURL = FileManager.default.temporaryDirectory.appendingPathComponent(folderName)
            
            // 2. Create the directory
            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            
            // 3. Write images with UNIQUE names to prevent overwriting
            for (index, item) in batch.images.enumerated() {
                let baseName = (item.originalName as NSString).deletingPathExtension
                // We append '_\(index)' to ensure that even if you have 5 files named "Photo.png",
                // they become "Photo_0.png", "Photo_1.png", etc.
                let uniqueFileName = "\(baseName)_resized_\(index).png"
                let fileURL = folderURL.appendingPathComponent(uniqueFileName)
                
                if let tiff = item.image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiff),
                   let png = bitmap.representation(using: .png, properties: [:]) {
                    try? png.write(to: fileURL)
                }
            }
            
            return SentTransferredFile(folderURL)
        }
    }
}
// MARK: - Main View
struct ContentView: View {
    @State private var targetWidth: String = "1242"
    @State private var targetHeight: String = "2208"
    
    @State private var inputImages: [(name: String, image: NSImage)] = []
    @State private var outputImages: [ProcessedImage] = []
    @State private var isHoveringDropZone = false

    var body: some View {
        VStack(spacing: 20) {
            
            // --- Top Controls ---
            HStack {
                TextField("Width", text: $targetWidth)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                Text("x")
                TextField("Height", text: $targetHeight)
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                
                Button("Process \(inputImages.count) Images") {
                    processImages()
                }
                .disabled(inputImages.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()

            HStack(spacing: 0) {
                
                // --- Input Drop Zone (Left Side) ---
                VStack {
                    Text("Drop Files Here")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 40))
                        .foregroundColor(isHoveringDropZone ? .accentColor : .secondary)
                    Text("\(inputImages.count) ready")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isHoveringDropZone ? Color.accentColor.opacity(0.1) : Color(nsColor: .windowBackgroundColor))
                .onDrop(of: [.image], isTargeted: $isHoveringDropZone) { providers in
                    loadIncomingImages(from: providers)
                    return true
                }

                Divider()
                
                // --- Output Drag Zone (Right Side) ---
                VStack {
                    // Header with Drag All Folder
                    HStack {
                        Text("Results")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if !outputImages.isEmpty {
                            VStack(spacing: 2) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                                Text("Drag All")
                                    .font(.system(size: 10))
                            }
                            .padding(8)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                            // NEW: Make this folder icon draggable for the whole batch
                            .draggable(BatchResult(images: outputImages))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))]) {
                            ForEach(outputImages) { processedWrapper in
                                Image(nsImage: processedWrapper.image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 80)
                                    .cornerRadius(8)
                                    .draggable(processedWrapper)
                            }
                        }
                        .padding()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .underPageBackgroundColor))
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    private func loadIncomingImages(from providers: [NSItemProvider]) {
        inputImages.removeAll()
        outputImages.removeAll()
        
        for provider in providers {
            if provider.canLoadObject(ofClass: NSImage.self) {
                let fileName = provider.suggestedName ?? "image"
                
                provider.loadObject(ofClass: NSImage.self) { image, error in
                    guard let nsImage = image as? NSImage else { return }
                    DispatchQueue.main.async {
                        self.inputImages.append((name: fileName, image: nsImage))
                    }
                }
            }
        }
    }
    
    private func processImages() {
        guard let w = Double(targetWidth), let h = Double(targetHeight) else { return }
        let targetSize = CGSize(width: w, height: h)
        
        outputImages.removeAll()
        
        for input in inputImages {
            if let resizedImage = input.image.resized(to: targetSize) {
                let processed = ProcessedImage(image: resizedImage, originalName: input.name)
                outputImages.append(processed)
            }
        }
        inputImages.removeAll()
    }
}

#Preview {
    ContentView()
}
