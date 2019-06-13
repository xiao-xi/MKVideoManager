//
//  VideoEditCommond.swift
//  Monkey
//
//  Created by holla on 2019/5/18.
//  Copyright © 2019 Monkey Squad. All rights reserved.
//

import Foundation

import AVFoundation

class VideoEditCommand: NSObject {
	deinit {
		print("VideoEditCommand deinit")
	}

	var outputVideoSetting: [String: Any]?

	var outputAudioSetting: [String: Any]?

	var exportUrl: URL?

	var exportFileType: AVFileType?

	func compositionVideoAndExport(with localUrl: URL, waterImage: UIImage? = nil, callback: @escaping OperationFinishHandler) {
		let (mixcomposition, videoComposition, audioMix) = VideoCompositionCommand.compostionVideo(videoUrl: localUrl, waterImage: waterImage)
		guard let mixCom = mixcomposition, let videoCom = videoComposition else {
			callback(nil)
			return
		}
		let exporter = VideoExportCommand()
		self.configureExport(with: exporter)
		VideoWatermarkCommond.applyViewEffectsToCompostion(videoCom, waterImage, videoCom.renderSize)
		exporter.exportVideo(with: mixCom, videoComposition: videoCom, audioMixTools: audioMix, exportType: .writer, callback: callback)
	}

	func compositionVideoAndExport(with commonImage: UIImage?, firstUrl: URL, maskUrl: URL, maskScale: CGFloat, maskOffset: CGPoint, callback: @escaping OperationFinishHandler) {
		let (mixcomposition, videoComposition, audioMix) = VideoCompositionCommand.compositionStoryWithSys(firstUrl, maskUrl, maskScale: maskScale, maskOffset: maskOffset)

		guard let mixCom = mixcomposition, let videoCom = videoComposition else {
			callback(nil)
			return
		}

		let exporter = VideoExportCommand()
		self.configureExport(with: exporter)

		VideoWatermarkCommond.applyFamousToCompostion(with: videoCom, commonWaterImage: commonImage, size: videoCom.renderSize)
		exporter.exportVideo(with: mixCom, videoComposition: videoCom, audioMixTools: audioMix, exportType: .writer, callback: callback)
	}

	fileprivate func configureExport(with exporter: VideoExportCommand) {
		if let videoSetting = self.outputVideoSetting {
			exporter.videoSetting = videoSetting
		}
		if let audioSetting = self.outputAudioSetting {
			exporter.audioSetting = audioSetting
		}

		if let fileType: AVFileType = self.exportFileType {
			exporter.exportFileType = fileType
		}

		if let url = self.exportUrl {
			exporter.exportUrl = url
		}
	}

	private func getDuration(_ videoUrl: URL) -> Double {
		let opts = [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: false)]
		let asset = AVURLAsset(url: videoUrl, options: opts)
		let seconds = Double(asset.duration.value) / Double(asset.duration.timescale)
		return seconds
	}
}