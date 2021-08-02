//
//  BatchDownloadViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 02.04.21.
//

import UIKit
import SwiftSoup

class BatchDownloadViewController: UIViewController {
    @IBOutlet weak var downloadAll: UILabel!
    @IBOutlet weak var gatherLinkBar: UIProgressView!
    @IBOutlet weak var gatherLinkProg: UILabel!

    var currentTr = 0
    var inte = 0
    var recdata = ""
    var total = GlobalVar.albumTags.tracks.count
    var downloading = false
    var cancelled = false

    override func viewDidDisappear(_ animated: Bool) {
        cancelled = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        currentTr = 0
        inte = 0
        recdata = ""
        total = GlobalVar.albumTags.tracks.count
        downloading = false
        cancelled = false
        gatherLinkBar.progress = 0.0
        initDownloadAll(type: DownloadVars.type, toDownload: DownloadVars.toDownload, name: DownloadVars.name)
    }

    func initDownloadAll(type: String, toDownload: [String], name: [String]) {
        if cancelled {
            return
        }
        print("PRE-COUNT: " + String(GlobalVar.albumTags.trackURL.count))
        self.downloadAll.text = "gathering".localized + "..."
        // gatherLinkBar.progress = 0.0
        print(currentTr)
        let completedUrl = URL(string: "https://downloads.khinsider.com" + toDownload[currentTr])!
        let task = URLSession.shared.dataTask(with: completedUrl) {(data, _, _) in
            self.recdata = String(data: data!, encoding: .utf8)!
            DispatchQueue.main.async {
                do {
                    let doc: Document = try SwiftSoup.parse(self.recdata)
                    let link: Element = try doc.getElementById("EchoTopic")!

                    for link in try! link.select("a") {
                        let urlPrev = try! link.attr("href")
                        if urlPrev.hasSuffix(type) {
                            print(urlPrev)
                            self.currentTr += 1
                            GlobalVar.download_queue.append(URL(string: urlPrev)!)
                            self.gatherLinkProg.text = "gathering".localized + ": " + String(self.currentTr) + " / " + String(GlobalVar.albumTags.trackURL.count)
                            self.gatherLinkBar.progress = Float(GlobalVar.download_queue.count) / Float(GlobalVar.albumTags.trackURL.count)
                            // print(Float16(GlobalVar.download_queue.count / GlobalVar.trackURL.count))
                            // print(GlobalVar.download_queue.count / GlobalVar.trackURL.count)
                            // print(String(GlobalVar.download_queue.count) + " ++ " + String(GlobalVar.trackURL.count))
                            // print(GlobalVar.trackURL.count)
                            if GlobalVar.download_queue.count == GlobalVar.albumTags.trackURL.count {
                                print(GlobalVar.download_queue)
                                self.downloadAll.text = "downloading".localized + "..."
                                // CALL DOWNLOAD HERE!
                                self.downloadAllStart()
                                break
                            }
                            self.initDownloadAll(type: type, toDownload: toDownload, name: name)
                        } else {
                            print("Invalid type!")
                        }
                    }
                } catch Exception.Error( _, let message) {
                    print(message)
                } catch {
                    print("error")
                }
            }
        }
        task.resume()
    }

    func downloadAllStart() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dataPath = documentsDirectory.appendingPathComponent(GlobalVar.albumTags.AlbumName)

        do {
            try FileManager.default.createDirectory(atPath: dataPath.path, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Error creating directory: \(error.localizedDescription)")
        }

        downloadAll.text = "downloading".localized + " " + GlobalVar.albumTags.AlbumName
        gatherLinkProg.text = "downloading".localized + " 1 / " + String(total)
        gatherLinkBar.progress = 0.0

        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        print(GlobalVar.download_queue)
        load(url: GlobalVar.download_queue, name: GlobalVar.albumTags.tracks, type: GlobalVar.download_type)
    }

    func load(url: [URL], name: [String], type: String) {
        if cancelled {
            return
        }
        print("Got here with request " + url[inte].absoluteString)

        let downloadTask = URLSession.shared.downloadTask(with: url[inte]) {
            urlOrNil, _, _ in

            guard let fileURL = urlOrNil else { return }
            do {
                let documentsURL = try
                    FileManager.default.url(for: .documentDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: false)
                let savedURL = documentsURL.appendingPathComponent(GlobalVar.albumTags.AlbumName + "/" + String(self.inte + 1) + ": " + name[self.inte] + GlobalVar.download_type)

                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                self.downloading = true
                print("Done!")
                DispatchQueue.main.async {
                    self.gatherLinkProg.text = "downloading".localized + " " + String(self.inte + 2) + " / " + String(self.total)
                    self.gatherLinkBar.progress = Float(self.inte + 2) / Float(self.total)
                    self.downloading = false
                    self.inte += 1
                    if self.inte == GlobalVar.albumTags.trackURL.count {
                        self.transitionToMain()
                        return
                    }
                    self.load(url: url, name: name, type: type)

                }
            } catch {
                DispatchQueue.main.async {
                    self.gatherLinkProg.text = "downloading".localized + " " + String(self.inte + 2) + " / " + String(self.total)
                    self.downloading = false
                    self.inte += 1
                    if self.inte == GlobalVar.albumTags.trackURL.count {
                        self.transitionToMain()
                        return
                    }
                    self.load(url: url, name: name, type: type)
                }
                print("file error: \(error)")
            }
        }
        downloadTask.resume()
    }

    func transitionToMain() {
        self.presentingViewController?.dismiss(animated: false)
        NotificationCenter.default.post(name: .downloadDone, object: nil)
    }

}

extension Notification.Name {
    static let downloadDone = Notification.Name("downloadDone")
}
