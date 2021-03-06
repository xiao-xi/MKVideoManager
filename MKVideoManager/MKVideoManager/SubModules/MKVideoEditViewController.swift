//
//  MKVideoEdit.swift
//  MKVideoManager
//
//  Created by holla on 2018/11/12.
//  Copyright © 2018 xiaoxiang. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import Photos

class MKVideoEditViewController: UIViewController {
    var backButton: UIButton!
    var textEditButton: UIButton!
    var coverButton: UIButton!
    var downButton: UIButton!
    var postButton: UIButton!
    var trashButton: UIButton!

    var playView: UIView!
    var playerLayer: AVPlayerLayer!
    var player: AVPlayer?
    var captionView: UIView?

	var colorsInputView: ColorsInputView!
	var colorType: ColorType = .Text

    var videoSize: CGSize?

    var maskViewManager: TextEditMaskManager!
    var deltaY: CGFloat = 0
    var maskViews: [UIView]?
    var textEditModel: FilterModel?
    var originCenter: CGPoint!
    var netRotation: CGFloat = 1;//旋转
    var lastScaleFactor: CGFloat! = 1  //放大、缩小

    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.white

        self.setSubViews()
        self.addKeyboardObserve()
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.navigationController?.isNavigationBarHidden = true
	}

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
		self.navigationController?.isNavigationBarHidden = false
    }

    func setupPlayer() {
        let opts: [String: Any] = [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(booleanLiteral: false)]
        let videoPath = Bundle.main.path(forResource: "220", ofType: "mp4")
        let videoUrl = URL(fileURLWithPath: videoPath!)
        let asset = AVURLAsset(url: videoUrl, options: opts)

        let playerItem = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: self.player)
        playerLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
		playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect

        self.playView.layer.addSublayer(playerLayer)
        self.addPlayerObserve()
        self.player?.play()
    }

    func setSubViews() {
        playView = UIView(frame: MKDefine.screenBounds)
        playView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        self.view.addSubview(playView)
        self.view.layer.masksToBounds = true
        self.setupPlayer()

        captionView = UIView(frame: MKDefine.screenBounds)
        captionView?.backgroundColor = UIColor.clear
        self.view.addSubview(captionView!)

        if self.backButton == nil {
            self.backButton = UIButton()
            self.backButton.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.left
            self.backButton.setImage(UIImage(named: "back"), for: .normal)
            self.backButton.addTarget(self, action: #selector(backNav), for: .touchUpInside)
            self.view.addSubview(self.backButton)
            self.backButton.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(4)
                make.top.equalToSuperview().offset(MKDefine.statusBarHeight)
                make.size.equalTo(CGSize(width: 60, height: 44))
            }
        }

        if self.textEditButton == nil {
            self.textEditButton = UIButton()
            self.textEditButton.setImage(UIImage(named: "text"), for: .normal)
            self.textEditButton.addTarget(self, action: #selector(textEditAction), for: .touchUpInside)
            self.view.addSubview(self.textEditButton)

            self.textEditButton.snp.makeConstraints { (make) in
                make.top.equalTo(self.backButton)
                make.right.equalToSuperview().offset(-8)
                make.size.equalTo(CGSize(width: 40, height: 40))
            }
        }

        if self.coverButton == nil {
            self.coverButton = UIButton()
            self.coverButton.setImage(UIImage(named: "cover"), for: .normal)
            self.coverButton.addTarget(self, action: #selector(chooseCoverAction), for: .touchUpInside)
            self.view.addSubview(self.coverButton)

            self.coverButton.snp.makeConstraints { (make) in
                make.top.equalTo(self.textEditButton.snp.bottom).offset(14)
                make.right.equalToSuperview().offset(-8)
                make.size.equalTo(CGSize(width: 40, height: 40))
            }
        }
        if self.downButton == nil {
            self.downButton = UIButton()
            self.downButton.setImage(UIImage(named: "save"), for: .normal)
            self.downButton.addTarget(self, action: #selector(downAction), for: .touchUpInside)
            self.view.addSubview(self.downButton)
            self.downButton.snp.makeConstraints { (make) in
                make.left.equalToSuperview().offset(8)
                make.bottom.equalToSuperview().offset(-20)
                make.size.equalTo(CGSize(width: 40, height: 44))
            }
        }

        if self.postButton == nil {
            self.postButton = UIButton()
            self.postButton.setTitle("Post to 🌴", for: .normal)
            self.postButton.titleLabel?.font = UIFont(name: "SFUIText-Medium", size: 17)
            self.postButton.setTitleColor(UIColor.black, for: .normal)
            self.postButton.backgroundColor = UIColor(red: 1, green: 252 / 255, blue: 1 / 255, alpha: 1)
            self.postButton.layer.cornerRadius = 20
            self.postButton.addTarget(self, action: #selector(postAction), for: .touchUpInside)
            self.view.addSubview(self.postButton)

            self.postButton.snp.makeConstraints { (make) in
                make.bottom.equalTo(self.downButton.snp.bottom)
                make.right.equalToSuperview().offset(-14)
                make.size.equalTo(CGSize(width: 117, height: 40))
            }
        }

        if self.trashButton == nil {
            self.trashButton = UIButton()
            self.trashButton.setImage(UIImage(named: "trash"), for: .normal)
            self.trashButton.isHidden = true
            self.view.addSubview(self.trashButton)
            self.trashButton.snp.makeConstraints { (make) in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(-20)
                make.size.equalTo(CGSize(width: 40, height: 40))
            }
        }

		self.maskViewManager = TextEditMaskManager.shared
		self.maskViewManager.delegate = self
		self.view.addSubview(self.maskViewManager.maskView)
//		self.maskView.snp.makeConstraints { (make) in
//			make.edges.equalToSuperview().inset(UIEdgeInsets.zero)
//		}
		self.colorsInputView = ColorsInputView(frame: CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: 44))
		self.colorsInputView.delegate = self

		self.view.addSubview(self.colorsInputView)
    }
    // MARK: 
    func showMask() {
        self.toggleAcionViewHide(true)
        self.maskViewManager.showMaskViewWithView(nil)
		self.maskViewManager.editTextView.becomeFirstResponder()
    }

    func toggleAcionViewHide(_ isHide: Bool) {
        self.backButton.isHidden = isHide
        self.textEditButton.isHidden = isHide
        self.coverButton.isHidden = isHide
        self.downButton.isHidden = isHide
        self.postButton.isHidden = isHide
    }

    func togglePanActionViewHide(_ subHide: Bool) {
        self.toggleAcionViewHide(subHide)
        self.trashButton.isHidden = !subHide
    }

    // MARK: Action
    @objc func backNav() {
        self.navigationController?.popViewController(animated: true)
    }

    @objc func textEditAction() {
        self.showMask()
    }

    @objc func chooseCoverAction() {
        let chooseCoverVC = MKVideoCoverViewController()
        self.navigationController?.pushViewController(chooseCoverVC, animated: true)
    }

    @objc func downAction() {
        let waterImage = self.captionView?.screenshot()
        let videoPath = Bundle.main.path(forResource: "220", ofType: "mp4")
        let videoUrl = URL(fileURLWithPath: videoPath!)

        MKVideoManager.default.exportWaterImageVideo(waterImage!, videoUrl)
    }

    @objc func postAction() {
        let subViews = self.captionView?.subviews
        self.addWatermarkViewWith(subViews![0])
//        self.addWatermarkViewWith(self.captionView!)
//        let treeVC = MKChooseTreeVIewController()
//        treeVC.setContentImage((self.captionView?.asImage())!)
//        self.navigationController?.pushViewController(treeVC, animated: true)
    }

    // MARK: deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension MKVideoEditViewController {
    // change To renderSize
    func getRenderOriginX(_ originX: CGFloat) -> CGFloat {
        return (videoSize?.width)! * originX / MKDefine.screenWidth
    }

    func getRenderOriginY(_ originY: CGFloat) -> CGFloat {
        return (videoSize?.height)! * originY / MKDefine.screenHeight
    }

    func getRenderOriginPoint(_ originPoint: CGPoint) -> CGPoint {
        return CGPoint(x: self.getRenderOriginX(originPoint.x), y: self.getRenderOriginY(originPoint.y))
    }

    func getRenderWidth(_ originWidth: CGFloat) -> CGFloat {
        return (videoSize?.width)! * originWidth / MKDefine.screenWidth
    }
    func getRenderHeight(_ originHeight: CGFloat) -> CGFloat {
        return (videoSize?.height)! * originHeight / MKDefine.screenHeight
    }
    func getRenderSize(_ originSize: CGSize) -> CGSize {
        let renderWidth = self.getRenderWidth(originSize.width)
        let rebderHeight = self.getRenderHeight(originSize.height)
        return CGSize(width: renderWidth, height: rebderHeight)
    }

    // MARK: watermark
    func addWatermarkViewWith(_ watermarkView: UIView) {
        //video
        let opts: [String: Any] = [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(booleanLiteral: false)]
        let videoPath = Bundle.main.path(forResource: "220", ofType: "mp4")
        let videoUrl = URL(fileURLWithPath: videoPath!)
        let asset = AVURLAsset(url: videoUrl, options: opts)
        //

        //video track
		let assetVideoTrack = asset.tracks(withMediaType: AVMediaType.video)[0]

        //composition
        let mutableComposition = AVMutableComposition()

       //video composition Track
		let videoCompositionTrack = mutableComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)
        //insert video track
		do {
			try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: asset.duration), of: assetVideoTrack, at: CMTime.zero)
		} catch {
			print(error.localizedDescription)
		}
        //
        let mutableVideoComposition = AVMutableVideoComposition()
		mutableVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)//30fps
        mutableVideoComposition.renderSize = assetVideoTrack.naturalSize
        self.videoSize = assetVideoTrack.naturalSize
        let passThroughnstruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
		passThroughnstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: mutableComposition.duration)
		let videoTrack: AVAssetTrack = mutableComposition.tracks(withMediaType: AVMediaType.video)[0]
        let passThroughLayer: AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        passThroughnstruction.layerInstructions = [passThroughLayer]

        mutableVideoComposition.instructions = [passThroughnstruction]

        //watermarkLayer
        //videoLayer and parentLayer
        let parentLayer: CALayer = CALayer()
        let videoLayer: CALayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: mutableVideoComposition.renderSize.width, height: mutableVideoComposition.renderSize.height)
        videoLayer.frame = CGRect(x: 0, y: 0, width: mutableVideoComposition.renderSize.width, height: mutableVideoComposition.renderSize.height)
        parentLayer.addSublayer(videoLayer)

        //把整个captionView加到视频中
        let copyView = self.captionView!.copyView()
        let captionLayer = CALayer()
        captionLayer.bounds = CGRect(x: 0, y: 0, width: mutableVideoComposition.renderSize.width, height: mutableVideoComposition.renderSize.height)
        captionLayer.contents = copyView.asImage().cgImage
         let waterLayer = CALayer()

        waterLayer.position = CGPoint(x: mutableVideoComposition.renderSize.width / 2, y: mutableVideoComposition.renderSize.height / 2)

        waterLayer.addSublayer(captionLayer)
        parentLayer.addSublayer(waterLayer)
        mutableVideoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)

        //export
        let baseDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let exportUrl = (baseDirectory.appendingPathComponent("export.mp4", isDirectory: false) as NSURL).filePathURL!
        deleteExistingFile(url: exportUrl)
        print("export path : \(exportUrl)")
        //这里设置导出质量
        let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)
        export!.outputURL = exportUrl
        export!.videoComposition = mutableVideoComposition
		export!.outputFileType = AVFileType.mov
        export!.exportAsynchronously(completionHandler: {() -> Void in
            switch export!.status {
            case .completed:
                let photos = PHPhotoLibrary.shared()
                photos.performChanges({
                }, completionHandler: { (_, _) in
                })
                break
            case .failed:
                break
            case .unknown:
                break
            case .waiting:
                break
            case .exporting:
                break
            case .cancelled:
                break
			@unknown default:
				break
			}
        })
    }
    func deleteExistingFile(url: URL) {
        let fileManager = FileManager.default
        do {
            try fileManager.removeItem(at: url)
        } catch _ as NSError {
        }
    }

    // MARK: player observe
    func addPlayerObserve() {
        NotificationCenter.default.addObserver(self, selector: #selector(playbackFInished), name: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
    }

	@objc func playbackFInished() {
        self.player?.seek(to: CMTime(value: 0, timescale: 1))
        self.player?.play()
    }

    func addKeyboardObserve() {
//		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(note:)), name:
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(note:)), name: UIResponder.keyboardWillShowNotification, object: nil)

		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHidden(note:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

	@objc func keyboardWillShow(note: NSNotification) {
        let userInfo = note.userInfo!
		let  keyBoardBounds = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
		let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue

        self.deltaY = keyBoardBounds.size.height
        print("deltaY: \(self.deltaY)")

        let animations:(() -> Void) = {
            //键盘的偏移量
			self.colorsInputView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height - 44 - self.deltaY, width: UIScreen.main.bounds.width, height: 44)
            self.maskViewManager.reloadEditViewControlHeight(self.deltaY)
        }

        if duration > 0 {
			let options = UIView.AnimationOptions(rawValue: UInt((userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).intValue << 16))

            UIView.animate(withDuration: duration, delay: 0, options: options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }
	@objc func keyboardWillHidden(note: NSNotification) {
        let userInfo = note.userInfo!
		let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue

        let animations:(() -> Void) = {
            //键盘的偏移量
            self.colorsInputView.frame = CGRect(x: 0, y: UIScreen.main.bounds.height, width: UIScreen.main.bounds.width, height: 44)
        }
        if duration > 0 {
			let options = UIView.AnimationOptions(rawValue: UInt((userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).intValue << 16))

            UIView.animate(withDuration: duration, delay: 0, options: options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }
}

extension MKVideoEditViewController: TextEditMaskManagerDelegate {
    func maskViewDidHide() {
		self.maskViewManager.editTextView.resignFirstResponder()
        self.toggleAcionViewHide(false)
    }

    func maskManagerDidOutputView(_ outputView: UIView) {
        let view = outputView as! EditTextView
        view.isEditable = false
        view.isSelectable = false

        let label = MKCaptionLabel()
        label.filterModel = view.filterModel
        label.attributedText = view.attributedText
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true
        label.layer.allowsEdgeAntialiasing = true
        self.captionView!.addSubview(label)
        self.addGestureToView(label)
        label.snp.makeConstraints { (make) in
            make.center.equalTo(label.filterModel!.center!)
            make.size.equalTo(label.filterModel!.size!)
        }
        label.layoutIfNeeded()
        if label.filterModel?.transform != nil {
            label.transform = (label.filterModel?.transform!)!
        }
    }
}

extension MKVideoEditViewController: UIGestureRecognizerDelegate {
    func addGestureToView(_ view: UIView) {
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        view.addGestureRecognizer(tapGes)
        let panGes = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        view.addGestureRecognizer(panGes)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchAction(_:)))
        pinchGesture.delegate = self
        view.addGestureRecognizer(pinchGesture)
        let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(rotationAction(_:)))
        rotateGesture.delegate = self
        view.addGestureRecognizer(rotateGesture)
    }

    // MARK: Gesture Action
	@objc func tap(_ gesture: UITapGestureRecognizer) {
//        let filterView = gesture.view as! EditTextView
        let filterView = gesture.view as! MKCaptionLabel
		filterView.superview?.bringSubviewToFront(filterView)
        self.maskViewManager.showMaskViewWithView(filterView)
		self.maskViewManager.editTextView.becomeFirstResponder()
        filterView.removeFromSuperview()
    }

	@objc func pan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self.view)
        //设置矩形的位置
//        let filterView = gesture.view as! EditTextView
        let filterView = gesture.view as! MKCaptionLabel
		filterView.superview?.bringSubviewToFront(filterView)
        if gesture.state == UIPanGestureRecognizer.State.began {
            originCenter = filterView.filterModel?.center
            self.togglePanActionViewHide(true)
        }
        var center = CGPoint(x: 0, y: 0)
        let locationPoint = gesture.location(in: self.view)
        if self.trashButton.frame.contains(locationPoint) {
            center = self.trashButton.center

            gesture.view?.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        } else {
            center = CGPoint(x: originCenter.x + translation.x, y: originCenter.y + translation.y)
            gesture.view?.transform = CGAffineTransform(scaleX: 1, y: 1)
        }

        if gesture.state == UIPanGestureRecognizer.State.ended {
            originCenter = center
            filterView.filterModel?.center = center
            filterView.filterModel?.rect = filterView.frame
            self.togglePanActionViewHide(false)
        }
        filterView.snp.updateConstraints { (make) in
            make.center.equalTo(center)
        }
    }

	@objc func pinchAction(_ gesture: UIPinchGestureRecognizer) {
        print("gesture.scale: \(gesture.scale)")
        let factor = gesture.scale

//        let filterView = gesture.view as! EditTextView
        let filterView = gesture.view as! MKCaptionLabel
        if gesture.state == UIGestureRecognizer.State.began {
            lastScaleFactor = 1
        }
        print("lastScaleFactor: \(String(describing: lastScaleFactor))")
        let newScale = 1 + factor - lastScaleFactor
        print("newScale: \(newScale)")
//        filterView.transform = CGAffineTransform(scaleX: factor, y: factor)
       filterView.transform = filterView.transform.scaledBy(x: newScale, y: newScale)
        lastScaleFactor = factor
        //状态是否结束，如果结束保存数据
        if gesture.state == UIGestureRecognizer.State.ended {
//            lastScaleFactor = factor
            filterView.filterModel?.scale = lastScaleFactor
            filterView.filterModel?.transform = filterView.transform
        }
    }

	@objc func rotationAction(_ gesture: UIRotationGestureRecognizer) {
        //浮点类型，得到sender的旋转度数
        print("rotation: \(gesture.rotation)")
        let rotation: CGFloat = gesture.rotation
//        let filterView = gesture.view as! EditTextView
        let filterView = gesture.view as! MKCaptionLabel

        if gesture.state == UIPanGestureRecognizer.State.began {
            netRotation = 0
        }
        print("netRotation: \(netRotation)")
        let newRotation = rotation - netRotation
        filterView.transform = filterView.transform.rotated(by: newRotation)
        print("newRotation: \(newRotation)")
        netRotation = rotation
        //状态结束，保存数据
		if gesture.state == UIGestureRecognizer.State.ended {
            filterView.filterModel?.rotation = netRotation
            filterView.filterModel?.transform = filterView.transform
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension MKVideoEditViewController: ColorsInputViewDelegate {
	enum ColorType {
		case Text
		case Background
	}

	func didSelectedColor(_ color: UIColor) {
		switch self.colorType {
		case .Text:

			break
		case .Background:

			break
		}
	}

	func didSelectedIndex(_ index: Int) {
	}
}
