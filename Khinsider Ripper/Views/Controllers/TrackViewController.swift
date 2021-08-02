//
//  TrackViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 02.04.21.
//

import UIKit
import SwiftSoup
import MBProgressHUD

class TrackViewController: UITableViewController {

    var recdata = ""
    var toDownload = ""

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return GlobalVar.albumTags.tracks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as! TrackUICell

        cell.trackNumberLabel.text = String(indexPath.row + 1)
        cell.trackNameLabel.text = GlobalVar.albumTags.tracks[indexPath.row]
        // print(GlobalVar.trackDuration)
        if GlobalVar.albumTags.trackDuration.count == 0 {
            cell.trackLengthLabel.text = ""
        } else {
            cell.trackLengthLabel.text = GlobalVar.albumTags.trackDuration[indexPath.row]
        }
        return cell
    }

    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let actionProvider: UIContextMenuActionProvider = { _ in

            let openInBrowser = UIAction(title: "open_browser".localized, image: UIImage(systemName: "globe")) {_ in
                let urlToOpen = URL(string: GlobalVar.base_url + GlobalVar.albumTags.trackURL[indexPath.row])
                UIApplication.shared.open(urlToOpen!)
            }

            var actions = [UIAction]()

            if GlobalVar.mp3 {
                var mp3Menu = "MP3"
                if GlobalVar.albumTags.trackSizeMP3.count != 0 {
                    mp3Menu = "MP3: " + GlobalVar.albumTags.trackSizeMP3[indexPath.row]
                }
                let mp3menu = UIAction(title: mp3Menu) {_ in
                    self.getFileToShare(type: ".mp3", toDownload: GlobalVar.albumTags.trackURL[indexPath.row], name: GlobalVar.albumTags.tracks[indexPath.row], indexPath: indexPath)
                }
                actions.append(mp3menu)
            }
            if GlobalVar.flac {
                var flacMenu = "FLAC"
                if GlobalVar.albumTags.trackSizeFLAC.count != 0 {
                    flacMenu = "FLAC: " + GlobalVar.albumTags.trackSizeFLAC[indexPath.row]
                }
                let flacmenu = UIAction(title: flacMenu) {_ in
                    self.getFileToShare(type: ".flac", toDownload: GlobalVar.albumTags.trackURL[indexPath.row], name: GlobalVar.albumTags.tracks[indexPath.row], indexPath: indexPath)
                }
                actions.append(flacmenu)
            }
            if GlobalVar.ogg {
                var oggMenu = "OGG"
                if GlobalVar.albumTags.trackSizeOGG.count != 0 {
                    oggMenu = "OGG: " + GlobalVar.albumTags.trackSizeOGG[indexPath.row]
                }
                let oggmenu = UIAction(title: oggMenu) {_ in
                    self.getFileToShare(type: ".ogg", toDownload: GlobalVar.albumTags.trackURL[indexPath.row], name: GlobalVar.albumTags.tracks[indexPath.row], indexPath: indexPath)
                }
                actions.append(oggmenu)
            }

            let share_file_menu = UIMenu(title: "share_file".localized, children: actions)
            let editMenu = UIMenu(title: "share_or_download".localized, image: UIImage(systemName: "square.and.arrow.up"), children: [
                UIAction(title: "share_link".localized) { _ in
                    self.popoverPresentationController?.sourceView = self.view
                    let items: [String] = ["checkout".localized + GlobalVar.base_url + GlobalVar.albumTags.trackURL[indexPath.row]]
                    let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
                    ac.popoverPresentationController?.sourceView = tableView
                    ac.popoverPresentationController?.sourceRect = tableView.rectForRow(at: indexPath)
                    self.present(ac, animated: true)
                },
                share_file_menu

            ])

            return UIMenu(title: GlobalVar.albumTags.tracks[indexPath.row], children: [openInBrowser, editMenu])
        }
        return UIContextMenuConfiguration(identifier: "unique-ID" as NSCopying, previewProvider: nil, actionProvider: actionProvider)
    }

    func getFileToShare(type: String, toDownload: String, name: String, indexPath: IndexPath) {
        let loadingNotification = MBProgressHUD.showAdded(to: self.view.window!, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.isUserInteractionEnabled = true
        loadingNotification.label.text = "downloading".localized
        loadingNotification.backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.2)

        let completed_url = URL(string: "https://downloads.khinsider.com" + toDownload)!
        let task = URLSession.shared.dataTask(with: completed_url) {(data, _, _) in
            self.recdata = String(data: data!, encoding: .utf8)!
            DispatchQueue.main.async {
                do {
                    let doc: Document = try SwiftSoup.parse(self.recdata)
                    let link: Element = try doc.getElementById("EchoTopic")!

                    for link in try! link.select("a") {
                        let url_prev = try! link.attr("href")
                        if url_prev.hasSuffix(type) {
                            print(url_prev)
                            self.load(url: URL(string: url_prev)!, name: name + type, indexPath: indexPath)
                            break
                        } else {
                            MBProgressHUD.hide(for: self.navigationController?.view ?? self.view, animated: true)
                            print("Invalid type!")
                        }
                    }
                } catch Exception.Error( _, let message) {
                    MBProgressHUD.hide(for: self.navigationController?.view ?? self.view, animated: true)
                    print(message)
                } catch {
                    MBProgressHUD.hide(for: self.navigationController?.view ?? self.view, animated: true)
                    print("error")
                }
            }
        }
        task.resume()
    }

    func load(url: URL, name: String, indexPath: IndexPath) {
        print("Got here with request " + url.absoluteString)
        let downloadTask = URLSession.shared.downloadTask(with: url) {
            urlOrNil, _, _ in

            guard let fileURL = urlOrNil else { return }
            do {
                let documentsURL = try
                    FileManager.default.url(for: .cachesDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: false)
                let savedURL = documentsURL.appendingPathComponent(name)

                if FileManager.default.fileExists(atPath: savedURL.path) {
                    DispatchQueue.main.async {
                        MBProgressHUD.hide(for: self.view.window!, animated: true)
                        var filesToShare = [Any]()
                        filesToShare.append(savedURL)
                        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                        activityViewController.popoverPresentationController?.sourceView = self.tableView
                        activityViewController.popoverPresentationController?.sourceRect = self.tableView.rectForRow(at: indexPath)
                        self.present(activityViewController, animated: true, completion: nil)
                    }
                    return
                }

                try FileManager.default.moveItem(at: fileURL, to: savedURL)
                DispatchQueue.main.async {
                    MBProgressHUD.hide(for: self.view.window!, animated: true)
                    var filesToShare = [Any]()
                    filesToShare.append(savedURL)
                    let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
                    activityViewController.popoverPresentationController?.sourceView = self.tableView
                    activityViewController.popoverPresentationController?.sourceRect = self.tableView.rectForRow(at: indexPath)
                    self.present(activityViewController, animated: true, completion: nil)
                }
            } catch {
                MBProgressHUD.hide(for: self.view.window!, animated: true)
                print("file error: \(error)")
            }
        }
        downloadTask.resume()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let loadingNotification = MBProgressHUD.showAdded(to: self.view.window!, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.isUserInteractionEnabled = true
        loadingNotification.label.text = "loading".localized
        loadingNotification.backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        GlobalVar.nowplaying = GlobalVar.albumTags.tracks[indexPath.row]
        let nowplaying = GlobalVar.albumTags.trackURL[indexPath.row]
        let completedUrl = URL(string: GlobalVar.base_url + nowplaying)
        let task = URLSession.shared.dataTask(with: completedUrl!) {(data, _, _) in
            self.recdata = String(data: data!, encoding: .utf8)!
            // print(String(data: data!, encoding: .utf8)!)
            DispatchQueue.main.async {
                print(self.recdata)
                do {
                    let doc: Document = try SwiftSoup.parse(self.recdata)
                    let link: Element = try doc.getElementById("EchoTopic")!

                    for link in try! link.select("a") {
                        let url_prev = try! link.attr("href")
                        if url_prev.hasSuffix(".mp3") {
                            GlobalVar.nowplayingurl = url_prev
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let vcontrol = storyboard.instantiateViewController(withIdentifier: "PlayerView")
                            vcontrol.modalPresentationStyle = .formSheet
                            self.present(vcontrol, animated: true)
                            MBProgressHUD.hide(for: self.view.window!, animated: true)
                            break
                        } else if url_prev.hasSuffix(".ogg") {
                            GlobalVar.nowplayingurl = url_prev
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let vcontrol = storyboard.instantiateViewController(withIdentifier: "PlayerView")
                            vcontrol.modalPresentationStyle = .formSheet
                            self.present(vcontrol, animated: true)
                            MBProgressHUD.hide(for: self.view.window!, animated: true)
                            break
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
}

class TrackUICell: UITableViewCell {
    @IBOutlet weak var trackNumberLabel: UILabel!
    @IBOutlet weak var trackNameLabel: UILabel!
    @IBOutlet weak var trackLengthLabel: UILabel!

}
