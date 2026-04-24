import AppKit

var fileSource: DispatchSourceFileSystemObject?

func monitorFile(filename: String, completion: @escaping (String) -> Void) {
    let fileURL = URL(fileURLWithPath: filename)
    let directoryURL = fileURL.deletingLastPathComponent()
    let fileName = fileURL.lastPathComponent
    print("Watching \(fileName) in \(directoryURL.path)")

    // Watch the file itself for content changes
    startFileWatch(fileURL: fileURL, fileName: fileName, onFileChange: completion)

    // Also watch the directory so we can re-establish the file watch
    // if the file gets deleted and recreated
    let dirFD = open(directoryURL.path, O_EVTONLY)
    guard dirFD >= 0 else {
        print("Failed to open directory for monitoring: \(directoryURL.path)")
        return
    }

    let dirSource: DispatchSourceFileSystemObject? = DispatchSource.makeFileSystemObjectSource(
        fileDescriptor: dirFD,
        eventMask: .write,
        queue: DispatchQueue.global(qos: .default)
    )
    guard let ds = dirSource else { return }

    ds.setEventHandler {
        // A file was added/removed/renamed in the directory — re-establish file watch
        print("Directory changed, re-establishing file watch")
        startFileWatch(fileURL: fileURL, fileName: fileName, onFileChange: completion)
    }

    ds.setCancelHandler {
        close(dirFD)
    }

    ds.resume()
}

private func startFileWatch(
    fileURL: URL, fileName: String, onFileChange: @escaping (String) -> Void
) {
    // Cancel any existing file watch
    fileSource?.cancel()
    fileSource = nil

    let fileFD = open(fileURL.path, O_EVTONLY)
    guard fileFD >= 0 else {
        print("File \(fileName) not found yet, waiting for directory event...")
        return
    }

    let source = DispatchSource.makeFileSystemObjectSource(
        fileDescriptor: fileFD,
        eventMask: [.write, .extend, .attrib, .delete, .rename],
        queue: DispatchQueue.global(qos: .default)
    )

    source.setEventHandler {
        let event = source.data
        if event.contains(.delete) || event.contains(.rename) {
            print("File \(fileName) was deleted/renamed, waiting for recreation...")
            source.cancel()
            fileSource = nil
            return
        }

        do {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            print("File \(fileName) changed. Contents:\n\(contents)")
            onFileChange(contents)
        } catch {
            print("Failed to read file \(fileName): \(error)")
        }
    }

    source.setCancelHandler {
        close(fileFD)
    }

    fileSource = source
    source.resume()
    print("Now watching file: \(fileName)")

    if let contents = try? String(contentsOf: fileURL, encoding: .utf8) {
        onFileChange(contents)
    }

}
