//
//  QRCodeTool.swift
//  QRCodeDemo
//
//  Created by 周际航 on 2017/5/4.
//  Copyright © 2017年 com.maramara. All rights reserved.
//

import UIKit

class QRCodeTool {
    static func detectQRCode(from image: UIImage) -> [String] {
        return self.privateDetectQRCode(from: image)
    }
    
    static func generateQRCode(message: String, imageWidth: CGFloat) -> UIImage? {
        return self.privateGenerateQRCode(message: message, imageWidth: imageWidth)
    }
}

private extension QRCodeTool {
    static func privateDetectQRCode(from image: UIImage) -> [String] {
        // 模拟器iphone iOS8.1 8.3 无法识别二维码，真机 iphone6s 8.3可识别
        guard let cgImage = image.cgImage else {return []}
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy : CIDetectorAccuracyHigh])
        let features = detector?.features(in: ciImage) ?? []
        var messages: [String] = []
        for feature in features {
            if let qrCodeFeature = feature as? CIQRCodeFeature {
                if let qrCode = qrCodeFeature.messageString {
                    messages.append(qrCode)
                }
            }
        }
        return messages
    }
    
    static func privateGenerateQRCode(message: String, imageWidth: CGFloat) -> UIImage? {
        guard imageWidth > 0 else {return nil}
        
        let data = message.data(using: .utf8)
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {return nil}
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("M", forKey: "inputCorrectionLevel")
        
        let onColor = UIColor.black
        let offColor = UIColor.white
        var parameters: [String : Any] = [:]
        if let textCIImage = qrFilter.outputImage {
            parameters["inputImage"] = textCIImage
        }
        parameters["inputColor0"] = CIColor(cgColor: onColor.cgColor)
        parameters["inputColor1"] = CIColor(cgColor: offColor.cgColor)
        let colorFilter = CIFilter(name: "CIFalseColor", withInputParameters: parameters)
        
        guard let colorCIImage = colorFilter?.outputImage else {return nil}
        guard let colorCGImage = CIContext().createCGImage(colorCIImage, from: colorCIImage.extent) else {return nil}
        
        UIGraphicsBeginImageContext(CGSize(width: imageWidth, height: imageWidth))
        guard let ctx = UIGraphicsGetCurrentContext() else {return nil}
        
        ctx.interpolationQuality = CGInterpolationQuality.none
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(colorCGImage, in: ctx.boundingBoxOfClipPath)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}
