//
//  ViewController.swift
//  Khinsider Ripper
//
//  Created by ptgms on 01.04.21.
//

import UIKit
import AVKit
import UIImageColors

class MusicPlayerView: UIViewController, UIContextMenuInteractionDelegate {
    @IBOutlet weak var albumArt: UIImageView!
    @IBOutlet weak var nowPlaying: UILabel!
    @IBOutlet weak var playPause: UIButton!
    @IBOutlet weak var goBack10Button: UIButton!
    @IBOutlet weak var goForward10Button: UIButton!
    @IBOutlet weak var progress: UISlider!
    @IBOutlet weak var behindCover: UIImageView!
    @IBOutlet weak var albumStackView: UIStackView!
    @IBOutlet weak var contextMenuButton: UIButton!
    @IBOutlet weak var AlbumNameLabel: UILabel!
    @IBOutlet weak var albumBlur: UIVisualEffectView!

    @IBOutlet weak var currentProg: UILabel!
    @IBOutlet weak var duration: UILabel!

    var playing = false
    var playable = false
    var currentplay = ""

    var playPauseButtonColor = UIColor.white

    var tapped = 0

    let defaults = UserDefaults.standard

    var favText = "Add to Favorites"

    var timeObserver: (Any)?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if GlobalVar.nowplaying == "" {
            GlobalVar.nowplaying = "nothingplay".localized
            GlobalVar.albumTags.coverURL.append("https://i.ibb.co/cgRJ97N/unknown.png")
            playable = false
            albumArt.isUserInteractionEnabled = false
        } else {
            playable = true
            albumArt.isUserInteractionEnabled = true
        }

        let favLoc = getIndex(for: GlobalVar.albumTags.AlbumName, elements: GlobalVar.favorites)
        if favLoc != -1 {
            favText = "addfav".localized
        } else {
            favText = "remove_fav".localized
        }

        progress.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)
        self.albumArt.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        if #available(iOS 13.0, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            albumArt.addInteraction(interaction)
            albumArt.isUserInteractionEnabled = false
        } else {
            let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressHappened))
            albumArt.addGestureRecognizer(recognizer)
        }

        for state: UIControl.State in [.normal, .selected, .application, .reserved, .focused, .highlighted] {

            if #available(iOS 13.0, *) {
                progress.setThumbImage(UIImage(named: "playStud")?.withTintColor(UIColor(named: "playBarColor")!), for: state)
            } else {
                progress.setThumbImage(UIImage(named: "playStud"), for: state)
            }

        }

        albumArt.clipsToBounds = true
        albumArt.layer.cornerRadius = 12
    }
    
    func getIndex(for name: String, elements: [AlbumCell]) -> Int {
        for i in 0..<elements.count {
            if elements[i].name == name {
                return i
            }
        }
        return -1
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player = nil
    }

    @available(iOS 13.0, *)
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ -> UIMenu? in
            return self.createContextMenu()
        }
    }

    @available(iOS 13.0, *)
    func createContextMenu() -> UIMenu {
        let saveToPhotos = UIAction(title: "add_photos".localized, image: UIImage(systemName: "photo")) { _ in
            self.saveAlbumArt()
        }
        return UIMenu(title: GlobalVar.nowplaying, children: [saveToPhotos])
    }

    @available(iOS 13.0, *)
    func createContextMenuButton() -> UIMenu {
        let safariAction = UIAction(title: "open_browser".localized, image: UIImage(systemName: "globe")) { _ in
            self.openInSafari()
        }
        let shareAction = UIAction(title: "share".localized, image: UIImage(systemName: "square.and.arrow.up")) { _ in
            self.shareTo()
        }
        let favorite = UIAction(title: favText, image: UIImage(systemName: "star.fill")) { _ in
            self.addRemoveFavorites()
        }
        return UIMenu(title: "", children: [safariAction, shareAction, favorite])
    }

    @IBAction func closeButtonPressed(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true)
    }

    fileprivate let seekDuration: Float64 = 10

    @IBAction func goBack10Press(_ sender: Any) {
        if player?.currentItem == nil {
            return
        }
        let playerCurrentTime = CMTimeGetSeconds(player!.currentTime())
        var newTime = playerCurrentTime - seekDuration

        if newTime < 0 {
            newTime = 0
        }
        let time2: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
        player!.seek(to: time2, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    }

    @IBAction func goForward10Press(_ sender: Any) {
        if player?.currentItem == nil {
            return
        }

        guard let duration = player?.currentItem?.duration else {
            return
        }
        let playerCurrentTime = CMTimeGetSeconds(player!.currentTime())
        let newTime = playerCurrentTime + seekDuration

        if newTime < (CMTimeGetSeconds(duration) - seekDuration) {
            let time2: CMTime = CMTimeMake(value: Int64(newTime * 1000 as Float64), timescale: 1000)
            player!.seek(to: time2, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        } else {
            player!.seek(to: duration)
        }
    }

    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                print("begin seek")
                playing = false
                if #available(iOS 13.0, *) {
                    playPause.setImage(UIImage(named: "play")?.withTintColor(playPauseButtonColor), for: .normal)
                } else {
                    playPause.setImage(UIImage(named: "play"), for: .normal)
                }
                player?.pause()
                break
            case .moved:
                if player?.currentItem == nil {
                    return
                }
                let duration: CMTime = (player?.currentItem!.asset.duration)!
                let seconds: Float64 = CMTimeGetSeconds(duration) * Double(progress.value)
                currentProg.text = self.stringFromTimeInterval(interval: seconds)
                break
            case .ended:
                if player?.currentItem == nil {
                    return
                }
                print("end seek at " + String(progress.value))
                let duration: CMTime = (player?.currentItem!.asset.duration)!
                let newCurrentTime: TimeInterval = Double(progress.value) * CMTimeGetSeconds(duration)
                let seekToTime: CMTime = CMTimeMakeWithSeconds(newCurrentTime, preferredTimescale: 600)
                player?.seek(to: seekToTime)
                playing = true
                if #available(iOS 13.0, *) {
                    playPause.setImage(UIImage(named: "pause")?.withTintColor(playPauseButtonColor), for: .normal)
                } else {
                    playPause.setImage(UIImage(named: "pause"), for: .normal)
                }
                player?.play()
                break
            default:
                break
            }
        }
    }

    @IBAction func contextMenuPressed(_ sender: Any) {
        if #available(iOS 14.0, *) {
            // We got native UIMenu implementation
        } else {
            openLongPressMenu()
        }
    }

    func stringFromTimeInterval(interval: TimeInterval) -> String {

        let interval = Int(interval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        // let hours = (interval / 3600)
        return String(format: "%02d:%02d", minutes, seconds)
    }

    override func viewWillAppear(_ animated: Bool) {
        if GlobalVar.nowplayingurl != "" {
            playable = true
            albumArt.isUserInteractionEnabled = true
        }

        if playable == true && currentplay != GlobalVar.nowplayingurl {
            if !Optional.isNil(timeObserver) {player?.removeTimeObserver(timeObserver!)}
            player = nil
            self.albumArt.transform = CGAffineTransform.identity
            audioPlayer(url: GlobalVar.nowplayingurl)
            currentplay = GlobalVar.nowplayingurl
            getData(from: URL(string: GlobalVar.albumTags.coverURL[0].addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)!) { data, response, error in
                guard let data = data, error == nil else { return }
                print(response?.suggestedFilename ?? URL(string: GlobalVar.albumTags.coverURL[0].addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)!.lastPathComponent)
                print("Download Finished")
                DispatchQueue.main.async {
                    self.albumArt.image = UIImage(data: data)
                    self.behindCover.image = UIImage(data: data)

                    self.updateColors(colorImage: self.albumArt.image!)
                }
            }
            let favLoc = getIndex(for: GlobalVar.albumTags.AlbumName, elements: GlobalVar.favorites)
            if favLoc != -1 {
                favText = "remove_fav".localized
            } else {
                favText = "addfav".localized
            }
        }
        nowPlaying.text = GlobalVar.nowplaying
        AlbumNameLabel.text = GlobalVar.albumTags.AlbumName

        if #available(iOS 14.0, *) {
            contextMenuButton.menu = createContextMenuButton()
            contextMenuButton.showsMenuAsPrimaryAction = true
        } else {
            // Fallback on earlier versions
        }
    }

    func updateColors(colorImage: UIImage) {
        colorImage.getColors(quality: .lowest) { [self] colors in
            UIView.animate(withDuration: 1.0) {
                self.nowPlaying.textColor = colors?.primary
                self.currentProg.textColor = colors?.primary
                self.duration.textColor = colors?.primary
                self.playPause.tintColor = colors?.primary
                self.progress.thumbTintColor = colors?.primary
                self.progress.tintColor = colors?.primary
                self.AlbumNameLabel.textColor = colors?.secondary

                self.albumBlur.backgroundColor = colors?.background.withAlphaComponent(0.2)

                playPauseButtonColor = colors!.primary

                if #available(iOS 13.0, *) {
                    self.contextMenuButton.setImage(UIImage(named: "contextMenu")?.withTintColor(colors!.primary), for: .normal)
                    self.goBack10Button.setImage(UIImage(named: "gobackward_10")?.withTintColor(colors!.primary), for: .normal)
                    self.goForward10Button.setImage(UIImage(named: "goforward_10")?.withTintColor(colors!.primary), for: .normal)
                    if playing {
                        self.playPause.setImage(UIImage(named: "pause")?.withTintColor(playPauseButtonColor), for: .normal)
                    } else {
                        self.playPause.setImage(UIImage(named: "play")?.withTintColor(playPauseButtonColor), for: .normal)
                    }
                }
            }

        }
    }

    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }

    @objc func playerItemDidReachEnd(notification: NSNotification) {
        player?.seek(to: CMTime.zero)
        player?.play()
    }
    // Remove Observer
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func openInSafari() {
        let url = URL(string: GlobalVar.nowplayingurl)!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }

    var player: AVPlayer?
    func audioPlayer(url: String) {
        do {
            AVAudioSession.sharedInstance()
            player = AVPlayer(url: URL.init(string: url)!)
            player?.play()
            try! AVAudioSession.sharedInstance().setCategory(.playback)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(playerItemDidReachEnd),
                                                   name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                   object: nil)
            playing = true
            if #available(iOS 13.0, *) {
                playPause.setImage(UIImage(named: "pause")?.withTintColor(playPauseButtonColor), for: .normal)
            } else {
                playPause.setImage(UIImage(named: "pause"), for: .normal)
            }
            self.duration.text = self.player?.currentItem?.asset.duration.positionalTime
            self.timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1/30.0, preferredTimescale: Int32(NSEC_PER_SEC)), queue: nil) { time in
                let duration = CMTimeGetSeconds((self.player?.currentItem?.asset.duration)!)
                self.progress.value = Float((CMTimeGetSeconds(time) / duration))
                self.currentProg.text = time.positionalTime
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        playing = false
        if #available(iOS 13.0, *) {
            playPause.setImage(UIImage(named: "play")?.withTintColor(playPauseButtonColor), for: .normal)
        } else {
            playPause.setImage(UIImage(named: "play"), for: .normal)
        }
        player?.pause()
        UIView.animate(withDuration: 0.1,
                       animations: {
                        self.albumArt.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        })
    }

    @IBAction func playPausePressed(_ sender: Any) {
        UIView.animate(withDuration: 0.1,
                       animations: {
                        self.playPause.transform = CGAffineTransform.identity
        },
                       completion: { _ in
                        UIView.animate(withDuration: 0.1) {
                            self.playPause.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                        }
        })
        if playing == true {
            playing = false
            if #available(iOS 13.0, *) {
                playPause.setImage(UIImage(named: "play")?.withTintColor(playPauseButtonColor), for: .normal)
            } else {
                playPause.setImage(UIImage(named: "play"), for: .normal)
            }
            player?.pause()
            UIView.animate(withDuration: 0.1,
                           animations: {
                            self.albumArt.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            })
        } else {
            playing = true
            if #available(iOS 13.0, *) {
                playPause.setImage(UIImage(named: "pause")?.withTintColor(playPauseButtonColor), for: .normal)
            } else {
                playPause.setImage(UIImage(named: "pause"), for: .normal)
            }
            player?.play()
            UIView.animate(withDuration: 0.1,
                           animations: {
                            self.albumArt.transform = CGAffineTransform.identity
            })
        }
    }

    func saveAlbumArt() {
        if let pickedImage = albumArt.image {
            UIImageWriteToSavedPhotosAlbum(pickedImage, self, nil, nil)
        }
    }

    func shareTo() {
        self.popoverPresentationController?.sourceView = self.view
        let items: [Any] = ["checkout".localized + GlobalVar.album_url!.absoluteString]
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        ac.popoverPresentationController?.sourceView = albumArt
        ac.popoverPresentationController?.sourceRect = albumArt.frame
        present(ac, animated: true)
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
        
        self.defaults.set(try? PropertyListEncoder().encode(GlobalVar.favorites), forKey:"favorites")
    }

    @objc func longPressHappened(gestureRecognizer: UILongPressGestureRecognizer) {
        if GlobalVar.nowplayingurl == "" {
            return
        }
        if gestureRecognizer.state == .began {
            openLongPressMenu()
        }
    }

    func openLongPressMenu() {
        if #available(iOS 10.0, *) {
            let generator = UIImpactFeedbackGenerator(style: .light)
            if tapped != 1 {
                generator.impactOccurred()
            }
        }
        let alert = UIAlertController(title: GlobalVar.nowplaying, message: GlobalVar.nowplayingurl, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "open_browser".localized, style: .default, handler: { _ in
            self.openInSafari()

        }))
        alert.addAction(UIAlertAction(title: "share".localized, style: .default, handler: { _ in
            self.shareTo()
        }))
        alert.addAction(UIAlertAction(title: favText, style: .default, handler: { _ in
            self.addRemoveFavorites()
        }))

        alert.addAction(UIAlertAction(title: "add_photos".localized, style: .default, handler: { _ in
            self.saveAlbumArt()
        }))

        alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: { _ in
            return
        }))

        alert.popoverPresentationController?.sourceView = nowPlaying

        self.present(alert, animated: true, completion: nil)
    }

}

extension CMTime {
    var roundedSeconds: TimeInterval {
        return seconds.rounded()
    }
    var hours: Int { return Int(roundedSeconds / 3600) }
    var minute: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 3600) / 60) }
    var second: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 60)) }
    var positionalTime: String {
        return hours > 0 ?
            String(format: "%d:%02d:%02d",
                   hours, minute, second) :
            String(format: "%02d:%02d",
                   minute, second)
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

extension Optional {
    static func isNil(_ object: Wrapped) -> Bool {
        switch object as Any {
        case Optional<Any>.none:
            return true
        default:
            return false
        }
    }
}

extension UIColor {
    func adjust(by percentage: CGFloat = 30.0) -> UIColor? {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return UIColor(red: min(red + percentage/100, 1.0),
                            green: min(green + percentage/100, 1.0),
                            blue: min(blue + percentage/100, 1.0),
                            alpha: alpha)
        } else {
            return nil
        }
    }
}
