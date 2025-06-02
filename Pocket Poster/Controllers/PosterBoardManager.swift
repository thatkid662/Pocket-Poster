//
//  PosterBoardManager.swift
//  Pocket Poster
//
//  Created by lemin on 5/31/25.
//

import Foundation
import ZIPFoundation
import UIKit

class PosterBoardManager {
    static let ShortcutURL = "https://www.icloud.com/shortcuts/a28d2c02ca11453cb5b8f91c12cfa692"
    static let WallpapersURL = "https://cowabun.ga/wallpapers"
    
    private static func unzipFile(at url: URL) throws -> URL {
        let fileName = url.deletingPathExtension().lastPathComponent
        let fileData = try Data(contentsOf: url)
        let fileManager = FileManager()

        // Write the file to the Documents Directory
        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let path = docDir[0]
        let url = path.appending(path: fileName)

        // Remove All files in this directory
        let existingFiles = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        for fileUrl in existingFiles
        {
            try FileManager.default.removeItem(at: fileUrl)
        }

        // Save our Zip file
        try fileData.write(to: url, options: [.atomic])

        // Unzip the Zipped Up File
        var destinationURL = path
        if FileManager.default.fileExists(atPath: url.path())
        {
            destinationURL.append(path: "directory")
            try fileManager.unzipItem(at: url, to: destinationURL)
        }

        return destinationURL
    }
    
    static func runShortcut(named name: String) {
        guard let urlEncodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "shortcuts://run-shortcut?name=\(name)") else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    static func getDescriptorsFromTendie(_ url: URL) throws -> URL? {
        let unzippedDir = try unzipFile(at: url)
        
        for dir in try FileManager.default.contentsOfDirectory(at: unzippedDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            let fileName = dir.lastPathComponent
            if fileName.lowercased() == "descriptor" || fileName.lowercased() == "descriptors" {
                return dir
            }
        }
        return nil
    }
    
    static func randomizeWallpaperId(url: URL) throws {
        let randomizedID = Int.random(in: 9999...99999)
        var files = [URL]()
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator
            {
                do
                {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile!
                    {
                        files.append(fileURL)
                    }
                }
                catch
                {
                    print(error, fileURL)
                }
            }
        }
        
        func setPlistValue(file: String, key: String, value: Any, recursive: Bool = true) {
            // thanks gpt
            guard let plistData = FileManager.default.contents(atPath: file),
                  var plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
                return
            }
            
            plist[key] = value
            
            guard let updatedData = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0) else {
                return
            }
            
            do {
                try updatedData.write(to: URL(fileURLWithPath: file))
            } catch {
                print("Failed to write updated plist: \(error)")
            }
        }
        
        for file in files {
            switch file.lastPathComponent {
            case "com.apple.posterkit.provider.descriptor.identifier":
                try String(randomizedID).data(using: .utf8)?.write(to: file)
                
            case "com.apple.posterkit.provider.contents.userInfo":
                setPlistValue(file: file.path(), key: "wallpaperRepresentingIdentifier", value: randomizedID)
                
            case "Wallpaper.plist":
                setPlistValue(file: file.path(), key: "identifier", value: randomizedID, recursive: false)
                
            default:
                continue
            }
        }
    }
    
    static func applyTendies(_ urls: [URL], appHash: String) throws {
        let _ = try SymHandler.createDescriptorsSymlink(appHash: appHash)
        defer {
            SymHandler.cleanup()
        }
        for url in urls {
            // scope the resource
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            guard let descriptors = try getDescriptorsFromTendie(url) else { return } // TODO: Add error handling
            // create the folder
            for descr in try FileManager.default.contentsOfDirectory(at: descriptors, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                if descr.lastPathComponent != "__MACOSX" {
                    try randomizeWallpaperId(url: descr)
                    let newURL = SymHandler.getDocumentsDirectory().appendingPathComponent(UUID().uuidString, conformingTo: .directory)
                    try FileManager.default.moveItem(at: descr, to: newURL)
                    
                    do {
                        try FileManager.default.trashItem(at: newURL, resultingItemURL: nil)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            
            try? FileManager.default.removeItem(at: descriptors)
        }
    }
    
    static func clearCache() throws {
        let docDir = SymHandler.getDocumentsDirectory()
        for file in try FileManager.default.contentsOfDirectory(at: docDir, includingPropertiesForKeys: nil) {
            try FileManager.default.removeItem(at: file)
        }
    }
}
