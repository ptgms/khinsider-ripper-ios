//
//  SearchTableViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 01.04.21.
//

import UIKit
import SwiftSoup
import MobileCoreServices
import MBProgressHUD
import UIImageColors

struct AlbumCell: Codable {
    var name: String
    var link: String
}

struct AlbumTags {
    var tracks: [String]
    var trackDuration: [String]
    var AlbumName: String
    var trackURL: [String]
    var coverURL: [String]

    var tags: [String]
    var trackSizeMP3: [String]
    var trackSizeFLAC: [String]
    var trackSizeOGG: [String]
    
}

class SearchTableViewController: UITableViewController, UITableViewDragDelegate {
    @IBOutlet var tableViewer: UITableView!
    // MARK: Initialization of project specific variables
    // var linkArray = [String]()
    // var textArray = [String]()
    
    var albumArray = [AlbumCell]()

    let base_url = "https://downloads.khinsider.com/"
    let base_search_url = "search?search="
    let base_soundtrack_album_url = "game-soundtracks/album/"

    var recdata = ""

    var tracklist = [String]()
    var tracklisturl = [String]()
    var titlelength = [String]()

    var tags = [String]()

    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        let defaults = UserDefaults.standard
        
        if let data = defaults.value(forKey:"favorites") as? Data {
            GlobalVar.favorites = try! PropertyListDecoder().decode(Array<AlbumCell>.self, from: data)
        }

        let searchController = UISearchController(searchResultsController: nil)
        // searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "searchfor".localized
        searchController.searchBar.becomeFirstResponder()
        
        let tapToSearch: TapToSearchView = UIView.fromNib()
        tableView.backgroundView = tapToSearch

        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        // tableView.dropDelegate = self

        self.navigationItem.searchController = searchController
        self.definesPresentationContext = true
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return albumArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "khinCell", for: indexPath)

        if albumArray[indexPath.row].name == "err_no_results" {
            cell.textLabel?.text = "err_no_results".localized
            cell.detailTextLabel?.text = "err_no_results_det".localized
            cell.accessoryType = .none
            return cell
        }

        cell.textLabel?.text = albumArray[indexPath.row].name
        cell.detailTextLabel?.text = "Path: " + albumArray[indexPath.row].link.replacingOccurrences(of: base_url, with: "")
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        return self.dragItems(for: indexPath)
    }

    func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
        let completed_url = URL(string: base_url + albumArray[indexPath.row].link.replacingOccurrences(of: base_url, with: "")) // build the URL to drag

        let data = completed_url!.absoluteString.data(using: .utf8)
        let itemProvider = NSItemProvider()

        itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypeURL as String, visibility: .all) { completion in
            completion(data, nil)
            return nil
        }

        return [
            UIDragItem(itemProvider: itemProvider)
        ]
    }

    // MARK: TableView Select
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if albumArray[indexPath.row].name == "err_no_results" {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let preView = storyboard.instantiateViewController(withIdentifier: "albumDetails")

        // resseting all Variables to empty in case another album got selected before

        let loadingNotification = MBProgressHUD.showAdded(to: self.navigationController?.view ?? self.view, animated: true)
        // let loadingNotification = MBProgressHUD.showAdded(to: self.view.window!, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.isUserInteractionEnabled = true
        loadingNotification.label.text = "loading".localized
        loadingNotification.backgroundView.backgroundColor = UIColor.black.withAlphaComponent(0.2)

        GlobalVar.mp3 = false
        GlobalVar.flac = false
        GlobalVar.ogg = false

        GlobalVar.albumTags.coverURL = [String]()
        tags = [String]()
        tracklist = [String]()
        tracklisturl = [String]()
        titlelength = [String]()

        var titleMP3Size = [String]()
        var titleFLACSize = [String]()
        var titleOGGSize = [String]()

        GlobalVar.albumTags.AlbumName = ""
        GlobalVar.albumTags.tags = [String]()
        GlobalVar.albumTags.tracks = [String]()
        GlobalVar.albumTags.trackDuration = [String]()
        GlobalVar.albumTags.trackURL = [String]()

        // MARK: Begin main processing code

        let completed_url = URL(string: base_url + albumArray[indexPath.row].link.replacingOccurrences(of: base_url, with: "")) // build the URL to process
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
                    GlobalVar.albumTags.AlbumName = self.albumArray[indexPath.row].name

                    GlobalVar.albumTags.trackSizeMP3 = titleMP3Size
                    GlobalVar.albumTags.trackSizeFLAC = titleFLACSize
                    GlobalVar.albumTags.trackSizeOGG = titleOGGSize

                    // print(GlobalVar.trackSizeMP3)
                    // print(GlobalVar.trackSizeFLAC)

                    // Below we see me being clowned because I missed ONE LINE in the API documentation
                    // I am keeping it here as a momento because FUCK ME I AM STUPID I COULD'VE SAVED
                    // MYSELF SO MUCH TROUBLE FUCKKKKKKKK
                    MBProgressHUD.hide(for: self.navigationController?.view ?? self.view, animated: true)
                    self.splitViewController?.showDetailViewController(preView, sender: nil)
                    /*if (UIDevice.current.userInterfaceIdiom == .phone) {
                        tableView.deselectRow(at: indexPath, animated: true)
                        self.navigationController?.pushViewController(preView, animated: true)
                    } else {
                        self.splitViewController?.showDetailViewController(preView, sender: nil)//viewControllers[1] = preView
                    }*/
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

    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let actionProvider: UIContextMenuActionProvider = { _ in

            let openInBrowser = UIAction(title: "album_browser".localized, image: UIImage(systemName: "globe")) {_ in
                let completed_url = URL(string: self.base_url + self.albumArray[indexPath.row].link.replacingOccurrences(of: self.base_url, with: "")) // build the URL to open
                UIApplication.shared.open(completed_url!)
            }

            // let share_file_menu = UIMenu(title: "share_file".localized, children: actions)
            let shareMenu = UIAction(title: "share_album".localized, image: UIImage(systemName: "square.and.arrow.up")) { _ in
                self.popoverPresentationController?.sourceView = self.view
                let items: [String] = ["checkout".localized + self.albumArray[indexPath.row].link]
                let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
                ac.popoverPresentationController?.sourceView = tableView
                ac.popoverPresentationController?.sourceRect = tableView.rectForRow(at: indexPath)
                self.present(ac, animated: true)
            }

            var favText = "Placeholder"
            
            if self.getIndex(for: self.albumArray[indexPath.row].name, elements: GlobalVar.favorites) != -1 {
                favText = "remove_fav".localized
            } else {
                favText = "addfav".localized
            }

            let addRemoveFav = UIAction(title: favText, image: UIImage(systemName: "star")) { _ in
                let favLoc = self.getIndex(for: self.albumArray[indexPath.row].name, elements: GlobalVar.favorites)
                if favLoc != -1 {
                    GlobalVar.favorites.remove(at: favLoc)
                } else {
                    GlobalVar.favorites.append(AlbumCell(name: self.albumArray[indexPath.row].name, link: self.albumArray[indexPath.row].link))
                }

                self.defaults.set(try? PropertyListEncoder().encode(GlobalVar.favorites), forKey:"favorites")

                NotificationCenter.default.post(name: .updateFav, object: nil)
            }

            return UIMenu(title: self.albumArray[indexPath.row].name, children: [openInBrowser, shareMenu, addRemoveFav])
        }
        return UIContextMenuConfiguration(identifier: "unique-ID" as NSCopying, previewProvider: nil, actionProvider: actionProvider)
    }
    
    func getIndex(for name: String, elements: [AlbumCell]) -> Int {
        for i in 0..<elements.count {
            if elements[i].name == name {
                return i
            }
        }
        return -1
    }
    
    func update() {
        if albumArray.count == 0 {
            let NoResultView: NoResultsView = UIView.fromNib()
            tableView.backgroundView = NoResultView
        } else {
            tableView.backgroundView = nil
        }
        tableViewer.reloadData()
        
    }

    func search(searchTerm: String) {
        let LoadingView: LoadingView = UIView.fromNib()
        tableView.backgroundView = LoadingView
        albumArray.removeAll()
        let search = searchTerm.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
        let completed_url = URL(string: base_url + base_search_url + search)
        let task = URLSession.shared.dataTask(with: completed_url!) {(data, response, _) in
            self.recdata = String(data: data!, encoding: .utf8)!
            DispatchQueue.main.async {
                // Check if only one result, where Khinsider redirects to the album
                if response!.url!.absoluteString.contains("game-soundtracks/album") {
                    let resultName = response!.url!.absoluteString.replacingOccurrences(of: self.base_url + self.base_soundtrack_album_url, with: "")
                    if self.getIndex(for: resultName, elements: self.albumArray) != -1 {
                        return
                    }
                    self.albumArray.append(AlbumCell(name: resultName, link: response!.url!.absoluteString))
                    
                    self.update()
                    return
                }
                // print(self.recdata)
                do {
                    let doc: Document = try SwiftSoup.parse(self.recdata)
                    let link: Element = try doc.getElementById("EchoTopic")!

                    for row in try! link.select("p") {
                        for col in try! row.select("a") {
                            if try col.attr("href").contains("game-soundtracks/browse/") || col.attr("href").contains("/forums/") {
                                continue
                            }
                            if try !col.attr("href").contains("/album/") {
                                continue
                            }
                            let colContent = try! col.text()
                            let colHref = try! col.attr("href")
                            
                            self.albumArray.append(AlbumCell(name: colContent, link: colHref))
                        }
                    }

                    self.update()

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

extension SearchTableViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text?.replacingOccurrences(of: " ", with: "") != "" {
            print("Searching with: " + (searchBar.text ?? ""))
            _ = (searchBar.text ?? "")
            search(searchTerm: searchBar.text!)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        albumArray.removeAll()
        tableView.backgroundView = nil
        tableViewer.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        tableView.backgroundView = nil
    }
}

// MARK: - Global variables

struct GlobalVar {
    static var albumTags = AlbumTags(tracks: [String](), trackDuration: [String](), AlbumName: "", trackURL: [String](), coverURL: [String](), tags: [String](), trackSizeMP3: [String](), trackSizeFLAC: [String](), trackSizeOGG: [String]())
    
    static let base_url = "https://downloads.khinsider.com"

    static var ogg = false
    static var mp3 = false
    static var flac = false

    static var nowplaying = ""
    static var nowplayingurl = ""

    static var download_type = ""

    static var album_url = URL(string: "")

    static var download_queue: [URL] = []

    static var favorites = [AlbumCell]()
}

extension String {
    var localized: String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
    }

    func format(formatWith: String...) -> String {
        var returner = self

        for string in formatWith {
            returner = returner.replacingFirstOccurrencesOf(target: "%s", withString: string)
        }

        return returner
    }

    func replacingFirstOccurrencesOf(target: String, withString replaceString: String) -> String {
            if let range = self.range(of: target) {
                return self.replacingCharacters(in: range, with: replaceString)
            }
            return self
        }
}

extension UIView {
    class func fromNib<T: UIView>() -> T {
        return Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}
