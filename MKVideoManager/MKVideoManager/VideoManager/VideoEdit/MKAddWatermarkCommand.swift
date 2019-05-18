//
//  MKAddWatermarkCommand.swift
//  MKVideoManager
//
//  Created by holla on 2018/11/19.
//  Copyright © 2018 xiaoxiang. All rights reserved.
//

import Foundation

import AVFoundation

class MKVideoCompositionCommand: NSObject {
	
	static func compostionVideo(videoUrl: URL, waterImage: UIImage?) -> (AVComposition?, AVVideoComposition?, AVAudioMix?) {
		
		let opts = [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber.init(value: false)]
		let asset: AVURLAsset = AVURLAsset.init(url: videoUrl, options: opts)
		
		let mixComposition = AVMutableComposition()
		guard let videoTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
			return (nil, nil, nil)
		}
		self.setupVideoTrack(asset: asset, videoTrack: videoTrack, startTime: CMTime.zero)
		// AVMutableVideoCompositionLayerInstruction 对视频图层的操作，可以设置视频在指定时间的方向、位置、透明度、裁剪大小等
		let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTrack)

		//对视频轨道进行处理，调整视频，设置transform 和 opacity
		let (videoTransform, newSize) = self.transformRotation(from: videoTrack)
		videoLayerInstruction.setTransform(videoTransform, at: CMTime.zero)
		
		//opacity 默认为 1
		//		videoLayerInstruction.setOpacity(1, at: CMTime.zero)
		
		if let audioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)  {
			self.setupAudioTrack(asset: asset, audioTrack: audioTrack, startTime: CMTime.zero)
		}
		
		let mainInstruction = AVMutableVideoCompositionInstruction()
		
		//这里设置导出视频的时长
		let totoaRange: CMTimeRange = videoTrack.timeRange
		mainInstruction.timeRange = totoaRange
		mainInstruction.backgroundColor = UIColor.red.cgColor
		//videoCompositionToolWithPostProcessingAsVideoLayer 时需要为 true， default = true
		//mainInstruction.enablePostProcessing = true
		mainInstruction.layerInstructions = [videoLayerInstruction]
		
		let videoComposition = AVMutableVideoComposition()
		
		videoComposition.renderSize = newSize
		//		mainCompositionInst.renderScale = 1
		
		//合成需要执行的操作
		videoComposition.instructions = [mainInstruction]
		
		//frameDuration：视频帧的间隔 通常设置为30
		videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
		
		// 添加水印
		self.applyViewoEffectsToCompostion(videoComposition, waterImage, newSize)
		return (mixComposition, videoComposition, nil)
	}
	
	static func compositionVideo(with firstUrl: URL, maskUrl: URL, maskScale: CGFloat, maskOffset: CGPoint) -> (AVComposition?, AVVideoComposition?, AVAudioMix?) {
		// 1 AVURLAsset 初始化视频媒体文件
		let opts = [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber.init(value: false)]
		let asset: AVURLAsset = AVURLAsset.init(url: firstUrl, options: opts)
		let maskAsset: AVURLAsset = AVURLAsset.init(url: maskUrl, options: opts)
		// 2 AVMutableComposition 创建AVMutableComposition实例.
		let mixComposition = AVMutableComposition()
		
		//3 AVMutableCompositionTrack 获取视频通道实例
		// --------------------track 1----------------------
		guard let videoTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
			return (nil, nil, nil)
		}
		self.setupVideoTrack(asset: asset, videoTrack: videoTrack, startTime: CMTime.zero)
		// 3.1 AVMutableVideoCompositionLayerInstruction 对视频图层的操作，可以设置视频在指定时间的方向、位置、透明度、裁剪大小等
		let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTrack)
		//		let newSize = videoTrack.naturalSize
		//对视频轨道进行处理，调整视频，设置transform 和 opacity
		let (videoTransform, newSize) = self.transformRotation(from: videoTrack)
		videoLayerInstruction.setTransform(videoTransform, at: CMTime.zero)
		
		//opacity 默认为 1
		//		videoLayerInstruction.setOpacity(1, at: CMTime.zero)
		
		// --------------------track 2----------------------
		//3 AVMutableCompositionTrack 获取视频通道实例
		guard let maskTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
			
			return (nil, nil, nil)
		}
		self.setupVideoTrack(asset: maskAsset, videoTrack: maskTrack, startTime: CMTime.zero, suggestTimeRange: videoTrack.timeRange)
		// 3 设置合成的视频源
		// 3.1 AVMutableVideoCompositionLayerInstruction 对视频图层的操作，可以设置视频在指定时间的方向、位置、透明度、裁剪大小等
		let maskVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: maskTrack)
		//对视频轨道进行处理，调整视频，设置transform 和 opacity
		let (maskVideoTransform, maskSize) = self.transformRotation(from: maskTrack)
		var newTransForm = maskVideoTransform.translatedBy(x: maskOffset.x * UIScreen.main.scale, y: maskOffset.y * UIScreen.main.scale)
		newTransForm = newTransForm.scaledBy(x: maskScale, y: maskScale)
		maskVideoLayerInstruction.setTransform(newTransForm, at: CMTime.zero)
		print("firstSize: \(newSize)")
		print("secondSize: \(maskSize)")
		// 3.2 - Add instructions
		// AVMutableVideoCompositionInstruction 视频操作指令，设置合成视频的时长，背景颜色，合成视频的z轴层次等
		let mainInstruction = AVMutableVideoCompositionInstruction()
		
		//这里设置导出视频的时长
		let totoaRange: CMTimeRange = videoTrack.timeRange
		mainInstruction.timeRange = totoaRange
		mainInstruction.backgroundColor = UIColor.red.cgColor
		//videoCompositionToolWithPostProcessingAsVideoLayer 时需要为 true， default = true
		//mainInstruction.enablePostProcessing = true
		
		//为视频分层，对于添加在相同时间的视频layer，先添加的在最顶层，后添加的在下层
		mainInstruction.layerInstructions = [maskVideoLayerInstruction, videoLayerInstruction]
		
		// 4 AVMutableAudioMix 音频混合器，通过AVMutableAudioMixInputParameters 设置音频轨道
		let audioMixTools: AVMutableAudioMix = AVMutableAudioMix()
		var audioParameters: [AVMutableAudioMixInputParameters] = []
		
		if let audioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
			self.setupAudioTrack(asset: asset, audioTrack: audioTrack, startTime: CMTime.zero)
			let mixInputParameter: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters.init(track: audioTrack)
			
			mixInputParameter.setVolumeRamp(fromStartVolume: 1, toEndVolume: 1, timeRange: audioTrack.timeRange)
			
			mixInputParameter.trackID = audioTrack.trackID
			audioParameters.append(mixInputParameter)
			
		}
		
		if let maskAudioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
			self.setupAudioTrack(asset: maskAsset, audioTrack: maskAudioTrack, startTime: CMTime.zero, suggestTimeRange: videoTrack.timeRange)
			let mixInputParameter: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters.init(track: maskAudioTrack)
			
			mixInputParameter.setVolumeRamp(fromStartVolume: 1, toEndVolume: 1, timeRange: maskAudioTrack.timeRange)
			
			mixInputParameter.trackID = maskAudioTrack.trackID
			audioParameters.append(mixInputParameter)
		}
		
		audioMixTools.inputParameters = audioParameters
		// 5 AVMutableVideoComposition：合成器 管理所有视频轨道，可以决定最终视频的尺寸
		let videoComposition = AVMutableVideoComposition()
		
		videoComposition.renderSize = newSize
		//		mainCompositionInst.renderScale = 1
		
		//合成需要执行的操作
		videoComposition.instructions = [mainInstruction]
		
		//frameDuration：视频帧的间隔 通常设置为30
		videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
		
		return (mixComposition, videoComposition, audioMixTools)
	}
	
	static func compositionStoryWithSys(_ watermarkImage: UIImage?, _ videoUrl: URL, _ maskVideoUrl: URL, _ preVideoUrl: URL, maskScale: CGFloat, maskOffset: CGPoint) -> (AVComposition?, AVVideoComposition?, AVAudioMix?){
		// 1 AVURLAsset 初始化视频媒体文件
		let opts = [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber.init(value: false)]
		let preAsset: AVURLAsset = AVURLAsset.init(url: preVideoUrl, options: opts)
		let asset: AVURLAsset = AVURLAsset.init(url: videoUrl, options: opts)
		let maskAsset: AVURLAsset = AVURLAsset.init(url: maskVideoUrl, options: opts)
		// 2 AVMutableComposition 创建AVMutableComposition实例.
		let mixComposition = AVMutableComposition()
		
		//3 AVMutableCompositionTrack 获取视频通道实例
		// --------------------track 0 pre track----------------------
		guard let preTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
			return (nil, nil, nil)
		}
		self.setupVideoTrack(asset: preAsset, videoTrack: preTrack, startTime: CMTime.zero)
		
		// 3 设置合成的视频源
		// 3.1 AVMutableVideoCompositionLayerInstruction 对视频图层的操作，可以设置视频在指定时间的方向、位置、透明度、裁剪大小等
		let preLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: preTrack)
		//		let newSize = videoTrack.naturalSize
		//对视频轨道进行处理，调整视频，设置transform 和 opacity
		let (preTransform, preSize) = self.transformRotation(from: preTrack)
		preLayerInstruction.setTransform(preTransform, at: CMTime.zero)
		
		let preDuration: CMTime = preTrack.timeRange.duration
		preLayerInstruction.setOpacity(0, at: preDuration)
		// --------------------track 1----------------------
		guard let videoTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
			return (nil, nil, nil)
		}
		self.setupVideoTrack(asset: asset, videoTrack: videoTrack, startTime: preDuration)
		// 3 设置合成的视频源
		// 3.1 AVMutableVideoCompositionLayerInstruction 对视频图层的操作，可以设置视频在指定时间的方向、位置、透明度、裁剪大小等
		let videoLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: videoTrack)
//		let newSize = videoTrack.naturalSize
		//对视频轨道进行处理，调整视频，设置transform 和 opacity
		let (videoTransform, newSize) = self.transformRotation(from: videoTrack)
		videoLayerInstruction.setTransform(videoTransform, at: CMTime.zero)
		
		//opacity 默认为 1
		//		videoLayerInstruction.setOpacity(1, at: CMTime.zero)
		
		// --------------------track 2----------------------
		//3 AVMutableCompositionTrack 获取视频通道实例
		guard let maskTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
			
			return (nil, nil, nil)
		}
		self.setupVideoTrack(asset: maskAsset, videoTrack: maskTrack, startTime: preDuration, suggestTimeRange: videoTrack.timeRange)
		// 3 设置合成的视频源
		// 3.1 AVMutableVideoCompositionLayerInstruction 对视频图层的操作，可以设置视频在指定时间的方向、位置、透明度、裁剪大小等
		let maskVideoLayerInstruction = AVMutableVideoCompositionLayerInstruction.init(assetTrack: maskTrack)
		//对视频轨道进行处理，调整视频，设置transform 和 opacity
		let (maskVideoTransform, maskSize) = self.transformRotation(from: maskTrack)
		var newTransForm = maskVideoTransform.translatedBy(x: maskOffset.x * UIScreen.main.scale, y: maskOffset.y * UIScreen.main.scale)
		newTransForm = newTransForm.scaledBy(x: maskScale, y: maskScale)
		maskVideoLayerInstruction.setTransform(newTransForm, at: CMTime.zero)
		print("preSize: \(preSize)")
		print("firstSize: \(newSize)")
		print("secondSize: \(maskSize)")
		// 3.2 - Add instructions
		// AVMutableVideoCompositionInstruction 视频操作指令，设置合成视频的时长，背景颜色，合成视频的z轴层次等
		let mainInstruction = AVMutableVideoCompositionInstruction()
		
		//这里设置导出视频的时长
		let totoaRange: CMTimeRange = CMTimeRangeMake(start: CMTime.zero, duration: CMTimeAdd(preTrack.timeRange.duration, videoTrack.timeRange.duration))
		mainInstruction.timeRange = totoaRange
		mainInstruction.backgroundColor = UIColor.red.cgColor
		//videoCompositionToolWithPostProcessingAsVideoLayer 时需要为 true， default = true
		//mainInstruction.enablePostProcessing = true
	
		//为视频分层，对于添加在相同时间的视频layer，先添加的在最顶层，后添加的在下层
		mainInstruction.layerInstructions = [preLayerInstruction, maskVideoLayerInstruction, videoLayerInstruction]
		
		// 4 AVMutableAudioMix 音频混合器，通过AVMutableAudioMixInputParameters 设置音频轨道
		let audioMixTools: AVMutableAudioMix = AVMutableAudioMix()
		var audioParameters: [AVMutableAudioMixInputParameters] = []
		var preAudioDuration: CMTime = CMTime.zero
		if let preAudioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)  {
			self.setupAudioTrack(asset: preAsset, audioTrack: preAudioTrack, startTime: CMTime.zero)
			let mixInputParameter: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters.init(track: preAudioTrack)
			mixInputParameter.setVolumeRamp(fromStartVolume: 1, toEndVolume: 1, timeRange: preAudioTrack.timeRange)
			mixInputParameter.trackID = preAudioTrack.trackID
			audioParameters.append(mixInputParameter)
			preAudioDuration = preAudioTrack.timeRange.duration
		}
		
		if let audioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
			self.setupAudioTrack(asset: asset, audioTrack: audioTrack, startTime: preDuration)
			let mixInputParameter: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters.init(track: audioTrack)
			
			mixInputParameter.setVolumeRamp(fromStartVolume: 1, toEndVolume: 1, timeRange: audioTrack.timeRange)
			
			mixInputParameter.trackID = audioTrack.trackID
			audioParameters.append(mixInputParameter)
			
		}
		
		if let maskAudioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
			self.setupAudioTrack(asset: maskAsset, audioTrack: maskAudioTrack, startTime: preAudioDuration, suggestTimeRange: videoTrack.timeRange)
			let mixInputParameter: AVMutableAudioMixInputParameters = AVMutableAudioMixInputParameters.init(track: maskAudioTrack)

			mixInputParameter.setVolumeRamp(fromStartVolume: 1, toEndVolume: 1, timeRange: maskAudioTrack.timeRange)

			mixInputParameter.trackID = maskAudioTrack.trackID
			audioParameters.append(mixInputParameter)
			
		}

		audioMixTools.inputParameters = audioParameters
		// 5 AVMutableVideoComposition：合成器 管理所有视频轨道，可以决定最终视频的尺寸
		let videoComposition = AVMutableVideoComposition()
		
		videoComposition.renderSize = preSize
		//		mainCompositionInst.renderScale = 1
		
		//合成需要执行的操作
		videoComposition.instructions = [mainInstruction]
		
		//frameDuration：视频帧的间隔 通常设置为30
		videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
		
		// 6 添加水印
		self.applyViewoEffectsToCompostion(videoComposition, watermarkImage, newSize)
		
		return (mixComposition, videoComposition, audioMixTools)
	}
	
	static private func setupVideoTrack(asset: AVAsset, videoTrack: AVMutableCompositionTrack, startTime: CMTime, suggestTimeRange: CMTimeRange? = nil) {
		//3 视频通道  工程文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材
		let videoAssetTracks = asset.tracks(withMediaType: AVMediaType.video)
		if videoAssetTracks.isEmpty == true {
			//no video track error
			return
		}
		for videoAssetTrack: AVAssetTrack in videoAssetTracks {
			do{
				//把视频轨道数据加入到可变轨道中 这部分可以做视频裁剪TimeRange
				//如果有suggestTimeRange 需要判断videoAssetTrack.timeRange 是否在suggestTimeRange中
				//如果超出了，需要剪切
				if let suggest = suggestTimeRange, videoAssetTrack.timeRange.containsTimeRange(suggest) {
					try videoTrack.insertTimeRange(suggest, of: videoAssetTrack, at: startTime)
				} else {
					try videoTrack.insertTimeRange(videoAssetTrack.timeRange, of: videoAssetTrack, at: startTime)
				}
				
			}catch{
				print(error)
				return
			}
		}
	}
	
	static private func setupAudioTrack(asset: AVAsset, audioTrack: AVMutableCompositionTrack, startTime: CMTime, suggestTimeRange: CMTimeRange? = nil) {
		//音频采集通道
		let audioAssetTracks = asset.tracks(withMediaType: AVMediaType.audio)
		
		if audioAssetTracks.isEmpty == true {
			//无音频轨道
			return
		}
		for audioAssetTrack: AVAssetTrack in audioAssetTracks {
			do {
				//音频通道
				if let suggest = suggestTimeRange, audioAssetTrack.timeRange.containsTimeRange(suggest) {
					try audioTrack.insertTimeRange(suggest, of: audioAssetTrack, at: startTime)
				} else {
					try audioTrack.insertTimeRange(audioAssetTrack.timeRange, of: audioAssetTrack, at: startTime)
				}
				
			} catch {
				print(error)
				return
			}
		}
	}
	
	static private func transformRotation(from videoTrack: AVAssetTrack) -> (CGAffineTransform, CGSize) {
		// 视频方向修改
		let naturalSize = videoTrack.naturalSize
		var newNaturalSize = naturalSize
		//获取视频方向并修改transform
		let degree = self.degreeFromVideoFileWithURL(videoTrack)
		if degree != 0{
			var translateToCenter: CGAffineTransform = CGAffineTransform()
			var mixedTransform: CGAffineTransform = CGAffineTransform()
			if degree == 90.0 {
				translateToCenter = CGAffineTransform.init(translationX: naturalSize.height, y: 0.0)
				mixedTransform = translateToCenter.rotated(by: self.degreesToRadians(degree))
				newNaturalSize = CGSize.init(width: naturalSize.height, height: naturalSize.width)
			}else if degree == 180.0 {
				translateToCenter = CGAffineTransform.init(translationX: naturalSize.width, y: naturalSize.height)
				mixedTransform = translateToCenter.rotated(by: self.degreesToRadians(degree))
				newNaturalSize = CGSize.init(width: naturalSize.width, height: naturalSize.height)
			}else if degree == 270.0 {
				translateToCenter = CGAffineTransform.init(translationX: 0.0, y: naturalSize.width)
				mixedTransform = translateToCenter.rotated(by: self.degreesToRadians(degree))
				newNaturalSize = CGSize.init(width: naturalSize.height, height: naturalSize.width)
			}
			
			return (mixedTransform, newNaturalSize)
		}
		
		return (videoTrack.preferredTransform, newNaturalSize)
	}
	
	
	/// 获取视频方向
	///
	/// - Parameter videoTrack: video track
	/// - Returns: degree
	static private func degreeFromVideoFileWithURL(_ videoTrack: AVAssetTrack) -> CGFloat {
		var degress: CGFloat = 0.0
		let t:CGAffineTransform = videoTrack.preferredTransform
		if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
			// Portrait
			degress = 90.0;
		}else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
			// PortraitUpsideDown
			degress = 270.0;
		}else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
			// LandscapeRight
			degress = 0.0;
		}else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
			// LandscapeLeft
			degress = 180.0;
		}
		return degress
	}
	
	/// 设置水印
	///
	/// - Parameters:
	///   - compostion: 合成器
	///   - waterImage: 水印
	///   - size: naturalSize视频大小
	static private func applyViewoEffectsToCompostion(_ compostion: AVMutableVideoComposition,_ waterImage: UIImage?,_ size: CGSize){
		let overlayLayer = CALayer.init()
		overlayLayer.frame = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
		overlayLayer.masksToBounds = true
		
		let videoLayer = CALayer.init()
		
		videoLayer.frame = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
		
		if let image = waterImage {
			let imgLayer = CALayer.init()
			imgLayer.contents = image.cgImage
			
			if size.width / size.height == 9.0 / 16.0 {
				//如果比例是6：19
				imgLayer.bounds = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
			}else if size.width / size.height > 9.0 / 16.0 {
				//其他尺寸，如果比例大于6: 19，高度将被填充满，左右两边被裁剪
				imgLayer.bounds = CGRect.init(x: 0, y: 0, width: size.height * 9.0 / 16.0, height: size.height)
			}else if size.width / size.height < 9.0 / 16.0 {
				//如果比例小于6: 19,宽度被填充，上下两边被裁剪
				imgLayer.bounds = CGRect.init(x: 0, y: 0, width: size.width, height: size.width * 16.0 / 9.0)
			}
			
			imgLayer.position = CGPoint.init(x: size.width/2, y: size.height/2)
			overlayLayer.addSublayer(imgLayer)
			videoLayer.addSublayer(imgLayer)
		}
		let parentLayer = CALayer.init()
		parentLayer.frame = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
		
		parentLayer.addSublayer(videoLayer)
		parentLayer.addSublayer(overlayLayer)
		
		compostion.animationTool = AVVideoCompositionCoreAnimationTool.init(postProcessingAsVideoLayer: videoLayer, in: parentLayer)
	}
	
	/// 通过degree获取应该旋转的角度
	///
	/// - Parameter degrees: degree
	/// - Returns: Radians
	static private func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
		return CGFloat.pi * degrees / 180
	}
}
