//
//  FavoriteTableViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 03.04.21.
//

import UIKit
import SwiftSoup
import MBProgressHUD

class FavoriteTableViewController: UITableViewController {

    let base_url = "https://downloads.khinsider.com/"
    let base_search_url = "search?search="
    let base_soundtrack_album_url = "game-soundtracks/album/"

    var recdata = ""

    var tags = [String]()
    var album_name = ""
    var tracklist = [String]()
    var tracklisturl = [String]()
    var titlelength = [String]()
    var linkArray = [String]()
    var textArray = [String]()
    let defaults = UserDefaults.standard
    
    var favName = [String]()
    var displayFavName = [String]()

    override func viewDidLoad() {
        super.viewDidLoad()

        let loadingView: LoadingView = UIView.fromNib()
        tableView.backgroundView = loadingView

        // print("Favorites here!")
        // print(GlobalVar.fav_link)
        NotificationCenter.default.addObserver(self, selector: #selector(favReload), name: .updateFav, object: nil)

        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "search_fav".localized

        self.navigationItem.searchController = searchController
        self.definesPresentationContext = true
    }

    @objc func favReload() {
        getIndexNames(elements: GlobalVar.favorites)
        tableView.reloadData()
    }
    
    func getIndexNames(elements: [AlbumCell]) {
        favName = [String]()
        for i in 0..<elements.count {
            favName.append(elements[i].name)
        }
        displayFavName = favName
    }
    
    func getIndex(for name: String, elements: [AlbumCell]) -> Int {
        for i in 0..<elements.count {
            if elements[i].name == name {
                return i
            }
        }
        return -1
    }

    override func viewDidAppear(_ animated: Bool) {
        getIndexNames(elements: GlobalVar.favorites)
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if GlobalVar.favorites.count == 0 {
            tableView.backgroundView = nil
        }
        return displayFavName.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.backgroundView = nil

        let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell")

        cell?.textLabel?.text = displayFavName[indexPath.row]
        // print(GlobalVar.favorites)
        
        cell?.detailTextLabel?.text = GlobalVar.favorites[getIndex(for: displayFavName[indexPath.row], elements: GlobalVar.favorites)].link.replacingOccurrences(of: base_url, with: "")

        return cell!
    }

    @IBAction func optionsButton(_ sender: Any) {
        if self.tableView.isEditing == true {
            self.tableView.isEditing = false
            self.navigationItem.rightBarButtonItem?.title = "done".localized
        } else {
            self.tableView.isEditing = true
            self.navigationItem.rightBarButtonItem?.title = "edit".localized
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let preView = storyboard.instantiateViewController(withIdentifier: "albumDetails")

        let loadingNotification = MBProgressHUD.showAdded(to: self.navigationController?.view ?? self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.isUserInteractionEnabled = true
        loadingNotification.label.text = "loading".localized
        loadingNotification.backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.2)

        recdata = ""
        GlobalVar.mp3 = false
        GlobalVar.flac = false
        GlobalVar.ogg = false

        var titleMP3Size = [String]()
        var titleFLACSize = [String]()
        var titleOGGSize = [String]()

        GlobalVar.albumTags.coverURL = [String]()
        tags = [String]()
        tracklist = [String]()
        tracklisturl = [String]()
        titlelength = [String]()
        GlobalVar.albumTags.AlbumName = ""
        GlobalVar.albumTags.tags = [String]()
        GlobalVar.albumTags.tracks = [String]()
        GlobalVar.albumTags.trackURL = [String]()

        let favLinkSelectInRow = GlobalVar.favorites[favName.firstIndex(of: displayFavName[indexPath.row])!].link.replacingOccurrences(of: base_url, with: "")

        let completed_url = URL(string: base_url + favLinkSelectInRow) // build the URL to process
        GlobalVar.album_url = completed_url
        let task = URLSession.shared.dataTask(with: completed_url!) {(data, _, _) in
            self.recdata = String(data: data!, encoding: .utf8)! // store the received data as a string to be processed
            DispatchQueue.main.async {
                do {
                    let doc: Document = try SwiftSoup.parse(self.recdata) // start swiftsoup tasks

                    for element in try doc.select("img").array() { // for every image on the site store the URL
                        let imgurl = try! element.attr("src")
                        if imgurl.hasPrefix("/album_views.php") {
                            GlobalVar.albumTags.coverURL.append("https://i.ibb.co/cgRJ97N/unknown.png")
                        } else {
                            GlobalVar.albumTags.coverURL.append(try! element.attr("src"))
                        }
                    }

                    let link: Element = try doc.getElementById("songlist")!
                    for row in try! link.select("tbody") {
                        for col in try! row.select("tr") {
                            for title in try! col.select("tr") {
                                if title.id() == "songlist_header" || title.id() == "songlist_footer" {
                                    for tag in try! title.select("th") {
                                        self.tags.append(try! tag.text())
                                    }
                                    print("TAGS: ")
                                    print(self.tags)
                                    if self.tags.contains("FLAC") {
                                        GlobalVar.flac = true
                                        print("FLAC: true")
                                    }
                                    if self.tags.contains("MP3") {
                                        GlobalVar.mp3 = true
                                        print("MP3: true")
                                    }
                                    if self.tags.contains("OGG") {
                                        GlobalVar.ogg = true
                                        print("OGG: true")
                                    }
                                    GlobalVar.albumTags.tags = self.tags
                                }
                                var temptag = [String]()
                                let songname = self.tags.firstIndex(of: "Song Name")!
                                for titlename in try! title.select("td") {
                                    temptag.append(try! titlename.text())
                                    // print(temptag)
                                    let titleurl = try! titlename.select("a").attr("href")
                                    if titleurl != "" && !self.tracklisturl.contains(titleurl) {
                                        // print(titleurl)
                                        self.tracklisturl.append(titleurl)
                                    }
                                    if temptag.count == self.tags.count + 1 {
                                        self.titlelength.append(temptag[songname + 1])
                                        self.tracklist.append(temptag[songname])
                                        if GlobalVar.mp3 {
                                            titleMP3Size.append(temptag[self.tags.firstIndex(of: "MP3")! + 1])
                                        }
                                        if GlobalVar.flac {
                                            titleFLACSize.append(temptag[self.tags.firstIndex(of: "FLAC")! + 1])
                                        }
                                        if GlobalVar.ogg {
                                            titleOGGSize.append(temptag[self.tags.firstIndex(of: "OGG")! + 1])
                                        }

                                    }
                                }
                            }
                        }
                    }

                    GlobalVar.albumTags.tracks = self.tracklist
                    GlobalVar.albumTags.trackURL = self.tracklisturl
                    GlobalVar.albumTags.trackDuration = self.titlelength
                    GlobalVar.albumTags.AlbumName = self.displayFavName[indexPath.row]

                    GlobalVar.albumTags.trackSizeMP3 = titleMP3Size
                    GlobalVar.albumTags.trackSizeFLAC = titleFLACSize
                    GlobalVar.albumTags.trackSizeOGG = titleOGGSize

                    MBProgressHUD.hide(for: self.navigationController?.view ?? self.view, animated: true)
                    self.splitViewController?.showDetailViewController(preView, sender: nil)

                    print(self.tracklist.count)
                    print(self.tracklisturl.count)

                } catch Exception.Error( _, let message) {
                    print(message)
                } catch {
                    print("error")
                }
            }
        }
        task.resume()
    }

    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let actionProvider: UIContextMenuActionProvider = { _ in

            let openInBrowser = UIAction(title: "album_browser".localized, image: UIImage(systemName: "globe")) {_ in
                let urlToOpen = URL(string: GlobalVar.favorites[self.favName.firstIndex(of: self.displayFavName[indexPath.row])!].link)
                UIApplication.shared.open(urlToOpen!)
            }

            // let share_file_menu = UIMenu(title: "share_file".localized, children: actions)
            let shareMenu = UIAction(title: "share_album".localized, image: UIImage(systemName: "square.and.arrow.up")) { _ in
                self.popoverPresentationController?.sourceView = self.view
                let items: [String] = ["checkout".localized + GlobalVar.favorites[self.favName.firstIndex(of: self.displayFavName[indexPath.row])!].link]
                let acontrol = UIActivityViewController(activityItems: items, applicationActivities: nil)
                acontrol.popoverPresentationController?.sourceView = tableView
                acontrol.popoverPresentationController?.sourceRect = tableView.rectForRow(at: indexPath)
                self.present(acontrol, animated: true)
            }

            let removeFromFav = UIAction(title: "remove_fav".localized, image: UIImage(systemName: "minus.circle")) { _ in
                let toRemove = self.favName.firstIndex(of: self.displayFavName[indexPath.row])!
                GlobalVar.favorites.remove(at: toRemove)

                self.defaults.set(try? PropertyListEncoder().encode(GlobalVar.favorites), forKey:"favorites")
                self.tableView.reloadData()
                NotificationCenter.default.post(name: .updateFav, object: nil)
            }

            return UIMenu(title: self.favName[indexPath.row], children: [openInBrowser, shareMenu, removeFromFav])
        }
        return UIContextMenuConfiguration(identifier: "unique-ID" as NSCopying, previewProvider: nil, actionProvider: actionProvider)
    }

    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let remove = UITableViewRowAction(style: .destructive, title: "rmv".localized) { (_, indexPath) in
            let toRemove = self.favName.firstIndex(of: self.displayFavName[indexPath.row])!
            GlobalVar.favorites.remove(at: toRemove)
            self.defaults.set(try? PropertyListEncoder().encode(GlobalVar.favorites), forKey:"favorites")
            self.tableView.reloadData()
            NotificationCenter.default.post(name: .updateFav, object: nil)
        }
        return [remove]
    }

}

extension Notification.Name {
    static let updateFav = Notification.Name("updateFav")
}

extension FavoriteTableViewController: UISearchResultsUpdating, UISearchBarDelegate {
    func updateSearchResults(for searchController: UISearchController) {
        if searchController.searchBar.text == "!!RESET" {
            self.defaults.set(try? PropertyListEncoder().encode([AlbumCell]()), forKey:"favorites")
            exit(0)
        }
        if let searchText = searchController.searchBar.text, !searchText.isEmpty {
            displayFavName = favName.filter { (item) in
                item.localizedCaseInsensitiveContains(searchText)
            }
        } else {
            displayFavName = favName
        }

        self.tableView.reloadData()
    }
}
