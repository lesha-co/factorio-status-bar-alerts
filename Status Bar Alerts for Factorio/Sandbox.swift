import AppKit

private let bookmarkKey = "appSupportBookmark"

/// Try to restore a previously-saved security-scoped bookmark.
/// Returns the resolved URL (already calling `startAccessingSecurityScopedResource`) on success.
func restoreBookmarkAccess() -> URL? {
    guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
        return nil
    }

    do {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmarkData,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )

        if isStale {
            // Re-save the bookmark so it stays fresh
            saveBookmark(for: url)
        }

        guard url.startAccessingSecurityScopedResource() else {
            print("startAccessingSecurityScopedResource failed for \(url.path)")
            return nil
        }

        return url
    } catch {
        print("Failed to resolve bookmark: \(error)")
        return nil
    }
}

/// Present an open-panel so the user can grant access to Factorio's Application Support folder.
/// `completion` is called on the main thread with the granted URL (or `nil` if the user cancelled).
func requestAccessToAppSupport(directoryURL: URL, completion: @escaping (URL?) -> Void) {
    let openPanel = NSOpenPanel()
    openPanel.message = "Select Factorio's Application Support folder to allow monitoring alerts"
    openPanel.prompt = "Grant Access"
    openPanel.canChooseDirectories = true
    openPanel.canChooseFiles = false
    openPanel.allowsMultipleSelection = false
    openPanel.directoryURL = directoryURL

    openPanel.begin { response in
        if response == .OK, let url = openPanel.url {
            saveBookmark(for: url)

            // Begin accessing immediately so callers can use the URL right away
            if url.startAccessingSecurityScopedResource() {
                DispatchQueue.main.async { completion(url) }
            } else {
                print("startAccessingSecurityScopedResource failed after granting access")
                DispatchQueue.main.async { completion(nil) }
            }
        } else {
            DispatchQueue.main.async { completion(nil) }
        }
    }
}

// MARK: - Private helpers

private func saveBookmark(for url: URL) {
    do {
        let bookmark = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
    } catch {
        print("Failed to create bookmark: \(error)")
    }
}
