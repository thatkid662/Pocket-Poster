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
    
    static let MaxTendies = 10
    
    static func getTendiesStoreURL() -> URL {
        let tendiesStoreURL = SymHandler.getDocumentsDirectory().appendingPathComponent("KFC Bucket", conformingTo: .directory)
        // create it if it doesn't exist
        if !FileManager.default.fileExists(atPath: tendiesStoreURL.path()) {
            try? FileManager.default.createDirectory(at: tendiesStoreURL, withIntermediateDirectories: true)
        }
        return tendiesStoreURL
    }
    
    static func openPosterBoard() -> Bool {
        guard let obj = objc_getClass("LSApplicationWorkspace") as? NSObject else { return false }
        let workspace = obj.perform(Selector(("defaultWorkspace")))?.takeUnretainedValue() as? NSObject
        
        if let success = workspace?.perform(Selector(("openApplicationWithBundleID:")), with: "com.apple.PosterBoard") {
            return success != nil
        }
        
        return false
    }
    
    private static func unzipFile(at url: URL) throws -> URL {
        let fileName = url.deletingPathExtension().lastPathComponent
        let fileData = try Data(contentsOf: url)
        let fileManager = FileManager()

        // Write the file to the Documents Directory
        let path = SymHandler.getDocumentsDirectory().appendingPathComponent("UnzipItems", conformingTo: .directory).appendingPathComponent(UUID().uuidString)
        if !FileManager.default.fileExists(atPath: path.path()) {
            try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        }
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
    
    static func getDescriptorsFromTendie(_ url: URL) throws -> [String: [URL]]? {
        for dir in try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            let fileName = dir.lastPathComponent
            if fileName.lowercased() == "container" {
                // container support, find the extensions
                let extDir = dir.appending(path: "Library/Application Support/PRBPosterExtensionDataStore/61/Extensions")
                print(extDir.absoluteString)
                var retList: [String: [URL]] = [:]
                for ext in try FileManager.default.contentsOfDirectory(at: extDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                    let descrDir = ext.appendingPathComponent("descriptors")
                    retList[ext.lastPathComponent] = [descrDir]
                }
                return retList
            }
            else if fileName.lowercased() == "descriptor" || fileName.lowercased() == "descriptors" || fileName.lowercased() == "ordered-descriptor" || fileName.lowercased() == "ordered-descriptors" { // TODO: Add ordered descriptors
                return ["com.apple.WallpaperKit.CollectionsPoster": [dir]]
            }
            else if fileName.lowercased() == "video-descriptor" || fileName.lowercased() == "video-descriptors" {
                return ["com.apple.PhotosUIPrivate.PhotosPosterProvider": [dir]]
            }
        }
        // TODO: Add error handling here
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
        // organize the descriptors into their respective extensions
        var extList: [String: [URL]] = [:]
        for url in urls {
            let unzippedDir = try unzipFile(at: url)
            guard let descriptors = try getDescriptorsFromTendie(unzippedDir) else { continue } // TODO: Add error handling
            extList.merge(descriptors) { (first, second) in first + second }
        }
        
        defer {
            SymHandler.cleanup()
        }
        
        for (ext, descriptorsList) in extList {
            let _ = try SymHandler.createDescriptorsSymlink(appHash: appHash, ext: ext)
            for descriptors in descriptorsList {
                // create the folder
                for descr in try FileManager.default.contentsOfDirectory(at: descriptors, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
                    if descr.lastPathComponent != "__MACOSX" {
                        try randomizeWallpaperId(url: descr)
                        let newURL = SymHandler.getDocumentsDirectory().appendingPathComponent(UUID().uuidString, conformingTo: .directory)
                        try FileManager.default.moveItem(at: descr, to: newURL)
                        let trashURL = SymHandler.getDocumentsDirectory().appendingPathComponent(".Trash")
                        try FileManager.default.removeItem(at: newURL)
                    }
                }
            }
            SymHandler.cleanup()
        }
        
        // clean up all possible files
        for url in urls {
            try? FileManager.default.removeItem(at: SymHandler.getDocumentsDirectory().appendingPathComponent("UnzipItems", conformingTo: .directory))
            try? FileManager.default.removeItem(at: SymHandler.getDocumentsDirectory().appendingPathComponent(url.lastPathComponent))
            try? FileManager.default.removeItem(at: SymHandler.getDocumentsDirectory().appendingPathComponent(url.deletingPathExtension().lastPathComponent))
        }
    }
    
    static func clearCache() throws {
        SymHandler.cleanup()
        let docDir = SymHandler.getDocumentsDirectory()
        for file in try FileManager.default.contentsOfDirectory(at: docDir, includingPropertiesForKeys: nil) {
            try FileManager.default.removeItem(at: file)
        }
    }
}
