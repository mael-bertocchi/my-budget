import Foundation

/// The last document the device and the server agreed on, and the server revision it was stored at. A push names
/// that revision so the server can turn it away if someone else wrote since, and a merge measures both sides'
/// edits against the document. It is kept on disk so edits made offline survive the app being closed.
struct SyncBase: Codable, Equatable {
    var document: BudgetDocument
    var revision: Int

    static func load() -> SyncBase? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        return try? JSONCoding.decoder.decode(SyncBase.self, from: data)
    }

    func save() {
        guard let data = try? JSONCoding.encoder.encode(self) else { return }

        try? data.write(to: Self.fileURL, options: .atomic)
    }

    static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private static var fileURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "sync-base.json")
    }
}
