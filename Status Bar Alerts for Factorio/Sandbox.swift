
import AppKit

func requestAccessToAppSupport() {
    let openPanel = NSOpenPanel()
    openPanel.message = "Select Factorio's Application Support folder"
    openPanel.canChooseDirectories = true
    openPanel.canChooseFiles = false
    openPanel.allowsMultipleSelection = false
    
    // Start at Library/Application Support
    let appSupportURL = FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
    ).first
    openPanel.directoryURL = appSupportURL
    
    openPanel.begin { response in
        if response == .OK, let url = openPanel.url {
            // You now have access to this folder
            // Save the security-scoped bookmark for future access
            saveBookmark(for: url)
        }
    }
}

func saveBookmark(for url: URL) {
    do {
        let bookmark = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmark, forKey: "appSupportBookmark")
    } catch {
        print("Failed to create bookmark: \(error)")
    }
}

func accessSavedLocation() {
    guard let bookmark = UserDefaults.standard.data(forKey: "appSupportBookmark") else {
        return
    }
    
    do {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        
        guard url.startAccessingSecurityScopedResource() else {
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Access the folder here
        let files = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    } catch {
        print("Error: \(error)")
    }
}
