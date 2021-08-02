//
//  AlbumDetailViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 01.04.21.
//

import UIKit
import UIImageColors
import MarqueeLabel

class AlbumDetailViewController: UITableViewController, UIContextMenuInteractionDelegate {

    @IBOutlet weak var albumDetails: UITableViewCell!
    @IBOutlet weak var albumCover: UIImageView!
    @IBOutlet weak var albumName: UILabel!
    @IBOutlet weak var trackAmount: UILabel!
    @IBOutlet weak var availableFormats: UILabel!
    @IBOutlet weak var trackCountLabel: UILabel!
    @IBOutlet weak var addToFavText: UILabel!
    @IBOutlet weak var behindCoverBG: UIView!

    var currentTr = 0
    var recdata = ""

    var total = GlobalVar.albumTags.trackURL.count
    var image: Data = Data()

    var tapped = 0

    let defaults = UserDefaults.standard

    var favText = "addfav".localized
    
    func getIndex(for name: String, elements: [AlbumCell]) -> Int {
        for i in 0..<elements.count {
            if elements[i].name == name {
                return i
            }
        }
        return -1
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setViewControllers([self], animated: false)

        tableView.register(UINib(nibName: "TrackCell", bundle: nil), forCellReuseIdentifier: "TrackCell")
        albumName.text = GlobalVar.albumTags.AlbumName
        self.albumCover.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        trackAmount.text = "contains".localized + String(GlobalVar.albumTags.tracks.count) + "tracks".localized
        self.navigationController?.title = GlobalVar.albumTags.AlbumName
        currentTr = 0

        NotificationCenter.default.addObserver(self, selector: #selector(updateFavs), name: .updateFav, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(downloadFinished), name: .downloadDone, object: nil)

        if getIndex(for: GlobalVar.albumTags.AlbumName, elements: GlobalVar.favorites) != -1 {
            favText = "remove_fav".localized
        } else {
            favText = "addfav".localized
        }

        addToFavText.text = favText

        // print(GlobalVar.tracks)

        var avaible = "av_formats".localized

        if GlobalVar.flac {
            avaible += "FLAC "
        }
        if GlobalVar.mp3 {
            avaible += "MP3 "
        }
        if GlobalVar.ogg {
            avaible += "OGG "
        }

        availableFormats.text = avaible

        trackCountLabel.text = "view_all".localized.format(formatWith: String(GlobalVar.albumTags.tracks.count))

        albumCover.clipsToBounds = true
        albumCover.layer.cornerRadius = 12

        print(GlobalVar.albumTags.coverURL)
        do {
            getData(from: URL(string: GlobalVar.albumTags.coverURL[0].addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)!) { data, response, error in
                guard let data = data, error == nil else { return }
                print(response?.suggestedFilename ?? URL(string: GlobalVar.albumTags.coverURL[0].addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)!.lastPathComponent )
                print("Download Finished")
                DispatchQueue.main.async {
                    self.albumCover.image = UIImage(data: data)
                    self.image = data
                    self.albumCover.image!.getColors(quality: .lowest) { [self] colors in
                        UIView.animate(withDuration: 0.5) {
                            self.behindCoverBG.backgroundColor = colors?.background
                            self.albumName.textColor = colors?.primary
                            self.trackAmount.textColor = colors?.primary
                            self.availableFormats.textColor = colors?.secondary
                        }
                    }
                }
            }
        }

        if #available(iOS 13.0, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            albumDetails.addInteraction(interaction)
            albumDetails.isUserInteractionEnabled = true
        } else {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressHappened))
            albumDetails.addGestureRecognizer(recognizer)
        }

    }

    @objc func updateFavs() {
        if getIndex(for: GlobalVar.albumTags.AlbumName, elements: GlobalVar.favorites) != -1 {
            favText = "remove_fav".localized
        } else {
            favText = "addfav".localized
        }

        addToFavText.text = favText
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            return
        case 1:
            switch indexPath.row {
            case 0:
                UIApplication.shared.open(GlobalVar.album_url!)
                return
            case 1:
                addRemoveFavorites()
                return
            case 2:
                print("Download All")
                GlobalVar.download_queue = []
                let alert = UIAlertController(title: "question".localized, message: "format_ask".localized, preferredStyle: .actionSheet)
                if GlobalVar.mp3 {
                    alert.addAction(UIAlertAction(title: "MP3", style: .default, handler: { _ in
                        GlobalVar.download_type = ".mp3"
                        self.initDownloadAll(type: GlobalVar.download_type, toDownload: GlobalVar.albumTags.trackURL, name: GlobalVar.albumTags.tracks)
                    }))
                }
                if GlobalVar.flac {
                    alert.addAction(UIAlertAction(title: "FLAC", style: .default, handler: { _ in
                        GlobalVar.download_type = ".flac"
                        self.initDownloadAll(type: GlobalVar.download_type, toDownload: GlobalVar.albumTags.trackURL, name: GlobalVar.albumTags.tracks)
                    }))
                }
                if GlobalVar.ogg {
                    alert.addAction(UIAlertAction(title: "ogg", style: .default, handler: { _ in
                        GlobalVar.download_type = ".ogg"
                        self.initDownloadAll(type: GlobalVar.download_type, toDownload: GlobalVar.albumTags.trackURL, name: GlobalVar.albumTags.tracks)
                    }))
                }

                alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: { _ in
                    return
                }))

                alert.popoverPresentationController?.sourceView = tableView
                alert.popoverPresentationController?.sourceRect = tableView.rectForRow(at: indexPath)

                self.present(alert, animated: true, completion: nil)
                return
            default:
                print("Invalid!")
                return
            }
        case 2:
            print("Tracks")
            return
        default:
            print("Invalid!")
            return
        }
    }

    func addRemoveFavorites() {
        let favLoc = self.getIndex(for: GlobalVar.albumTags.AlbumName, elements: GlobalVar.favorites)
        if favLoc != -1 {
            GlobalVar.favorites.remove(at: favLoc)
            favText = "addfav".localized
        } else {
            GlobalVar.favorites.append(AlbumCell(name: GlobalVar.albumTags.AlbumName, link: GlobalVar.album_url?.absoluteString ?? ""))
            favText = "remove_fav".localized
        }

        addToFavText.text = favText

        self.defaults.set(try? PropertyListEncoder().encode(GlobalVar.favorites), forKey:"favorites")

        NotificationCenter.default.post(name: .updateFav, object: nil)
    }

    func initDownloadAll(type: String, toDownload: [String], name: [String]) {
        DownloadVars.type = type
        DownloadVars.toDownload = toDownload
        DownloadVars.name = name

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "downloadSheet")
        vc.modalPresentationStyle = .formSheet
        self.present(vc, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if UIDevice.current.userInterfaceIdiom == .phone {
                return 100
            } else {
                return 200
            }
        }
        return 44
    }

    override func viewWillAppear(_ animated: Bool) {
        let favLoc = self.getIndex(for: GlobalVar.albumTags.AlbumName, elements: GlobalVar.favorites)
        if favLoc != -1 {
            favText = "remove_fav".localized
        } else {
            favText = "addfav".localized
        }

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    @available(iOS 13.0, *)
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ -> UIMenu? in
            return self.createContextMenu()
        }
    }

    @available(iOS 13.0, *)
    func createContextMenu() -> UIMenu {
        let shareAction = UIAction(title: "share".localized, image: UIImage(systemName: "square.and.arrow.up")) { _ in
            self.sharePressed()
        }

        // This is a dirty solution, but I really do not care. I want that share sheet mmmmm

        var actions = [UIAction]()

        let saveToPhotos = UIAction(title: "add_photos_cover".localized, image: UIImage(systemName: "photo")) { _ in
            self.saveAlbumArt()
        }

        let saveShareToPhotos = UIAction(title: "add_photos_sheet".localized, image: UIImage(systemName: "text.below.photo")) { _ in
            self.saveSheet()
        }

        actions.append(saveToPhotos)
        actions.append(saveShareToPhotos)

        let savePhotoMenu = UIMenu(title: "add_photos".localized, image: UIImage(systemName: "square.and.arrow.down"), children: actions)

        return UIMenu(title: GlobalVar.albumTags.AlbumName, children: [shareAction, savePhotoMenu])
    }

    func saveAlbumArt() {
        if let pickedImage = albumCover.image {
            UIImageWriteToSavedPhotosAlbum(pickedImage, self, nil, nil)
        }
    }

    func saveSheet() {
        UIImageWriteToSavedPhotosAlbum(albumDetails.contentView.asImage(), self, nil, nil)
    }

    @objc func longPressHappened(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            if #available(iOS 10.0, *) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                if tapped != 1 {
                    generator.impactOccurred()
                }
            }
            let alert = UIAlertController(title: GlobalVar.albumTags.AlbumName, message: GlobalVar.album_url?.absoluteString, preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: "share".localized, style: .default, handler: { _ in
                self.sharePressed()
            }))

            alert.addAction(UIAlertAction(title: "add_photos".localized, style: .default, handler: { _ in
                self.saveAlbumArt()
            }))

            alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: { _ in
                return
            }))

            alert.popoverPresentationController?.sourceView = albumCover

            self.present(alert, animated: true, completion: nil)
        }
    }

    func sharePressed() {
        self.popoverPresentationController?.sourceView = self.view
        let items: [Any] = [albumDetails.contentView.asImage(), "checkout".localized + GlobalVar.album_url!.absoluteString]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        ac.popoverPresentationController?.sourceView = albumCover
        ac.popoverPresentationController?.sourceRect = albumCover.frame
        present(ac, animated: true)
    }

    @objc func downloadFinished() {
        let alertController = UIAlertController(title: "done".localized + "!", message: "tracksdone".localized, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "ok".localized, style: .default))

        self.present(alertController, animated: true, completion: nil)
    }

}

struct DownloadVars {
    static var type = ""
    static var toDownload = [String]()
    static var name = [String]()
}

extension UIView {
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
