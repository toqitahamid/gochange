import Foundation

/// Service for managing exercise form media (photos/videos)
class MediaService {
    private let fileManager = FileManager.default
    
    private var mediaFolderURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("ExerciseMedia")
    }
    
    init() {
        createMediaFolderIfNeeded()
    }
    
    private func createMediaFolderIfNeeded() {
        if !fileManager.fileExists(atPath: mediaFolderURL.path) {
            try? fileManager.createDirectory(at: mediaFolderURL, withIntermediateDirectories: true)
        }
    }
    
    /// Saves media data and returns the file path
    func saveMedia(data: Data, type: Exercise.MediaType, for exerciseId: UUID) -> String? {
        let fileExtension = type == .video ? "mp4" : "jpg"
        let fileName = "\(exerciseId.uuidString).\(fileExtension)"
        let fileURL = mediaFolderURL.appendingPathComponent(fileName)
        
        do {
            // Remove existing file if present
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving media: \(error)")
            return nil
        }
    }
    
    /// Loads media data from path
    func loadMedia(from path: String) -> Data? {
        return fileManager.contents(atPath: path)
    }
    
    /// Deletes media for an exercise
    func deleteMedia(for exerciseId: UUID) {
        let jpgPath = mediaFolderURL.appendingPathComponent("\(exerciseId.uuidString).jpg")
        let mp4Path = mediaFolderURL.appendingPathComponent("\(exerciseId.uuidString).mp4")
        
        try? fileManager.removeItem(at: jpgPath)
        try? fileManager.removeItem(at: mp4Path)
    }
    
    /// Gets the URL for an exercise's media if it exists
    func getMediaURL(for exerciseId: UUID) -> URL? {
        let jpgURL = mediaFolderURL.appendingPathComponent("\(exerciseId.uuidString).jpg")
        let mp4URL = mediaFolderURL.appendingPathComponent("\(exerciseId.uuidString).mp4")
        
        if fileManager.fileExists(atPath: mp4URL.path) {
            return mp4URL
        } else if fileManager.fileExists(atPath: jpgURL.path) {
            return jpgURL
        }
        
        return nil
    }
    
    /// Cleans up orphaned media files (files without corresponding exercises)
    func cleanupOrphanedMedia(validExerciseIds: Set<UUID>) {
        guard let contents = try? fileManager.contentsOfDirectory(at: mediaFolderURL, includingPropertiesForKeys: nil) else {
            return
        }
        
        for fileURL in contents {
            let fileName = fileURL.deletingPathExtension().lastPathComponent
            if let uuid = UUID(uuidString: fileName), !validExerciseIds.contains(uuid) {
                try? fileManager.removeItem(at: fileURL)
            }
        }
    }
    
    /// Returns the total size of media storage in bytes
    var totalStorageSize: Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(at: mediaFolderURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        return contents.reduce(0) { total, fileURL in
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }
    
    /// Formats storage size for display
    func formattedStorageSize() -> String {
        let bytes = totalStorageSize
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

