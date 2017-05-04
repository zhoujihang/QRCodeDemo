//
//  SystemQRCodeViewController.swift
//  QRCodeDemo
//
//  Created by 周际航 on 2017/5/4.
//  Copyright © 2017年 com.maramara. All rights reserved.
//

import UIKit
import AVFoundation

class SystemQRCodeViewController: UIViewController {
    
    fileprivate var device: AVCaptureDevice?
    fileprivate var input: AVCaptureInput?
    fileprivate var output: AVCaptureMetadataOutput?
    fileprivate var session: AVCaptureSession?
    
    fileprivate var scanRectView: UIView = UIView()
    fileprivate var previewLayer: AVCaptureVideoPreviewLayer?
    
    fileprivate var isReadMessage: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
}

private extension SystemQRCodeViewController {
    func setup() {
        self.setupCaptureSession()
        self.setupViews()
    }
    
    func setupCaptureSession() {
        guard let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else {
            debugPrint("\(type(of: self)): \(#function) line:\(#line) error captureDevice")
            return
        }
        
        // 输入
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            debugPrint("\(type(of: self)): \(#function) line:\(#line) error deviceInput")
            return
        }
        // 输出
        let dataOutput = AVCaptureMetadataOutput()
        dataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        // session
        let captureSession = AVCaptureSession()
        let present = UIScreen.main.bounds.size.height > 500 ? AVCaptureSessionPresetHigh : AVCaptureSessionPreset640x480
        captureSession.canSetSessionPreset(present)
        if captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
            // metadataObjectTypes 此属性需要在 output 加入 session 后才可设置
            dataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        }
        
        // session的视图内容
        guard let newLayer = AVCaptureVideoPreviewLayer(session: captureSession) else {
            debugPrint("\(type(of: self)): \(#function) line:\(#line) error create AVCaptureVideoPreviewLayer")
            return
        }
        newLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        newLayer.frame = UIScreen.main.bounds
        self.view.layer.insertSublayer(newLayer, at: 0)
        
        self.device = captureDevice
        self.input = deviceInput
        self.output = dataOutput
        self.session = captureSession
        self.previewLayer = newLayer
        
        self.session?.startRunning()
    }
    func setupViews() {
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.scanRectView)
        
        let (scanRect, scanPercentRect) = self.interestScanRect()
        self.output?.rectOfInterest = scanPercentRect
        self.scanRectView.bounds = scanRect
        self.scanRectView.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        self.scanRectView.layer.borderColor = UIColor.red.cgColor
        self.scanRectView.layer.borderWidth = 1
        self.scanRectView.backgroundColor = UIColor.clear
    }
    
    // 获取扫描区域frame, 以及rectOfInterest
    private func interestScanRect() -> (scanRect: CGRect, scanPercentRect: CGRect) {
        let screenSize = UIScreen.main.bounds.size
        
        let scanSize = CGSize(width: screenSize.width*3/4, height: screenSize.width*3/4)
        let scanOrigin = CGPoint(x: (screenSize.width-scanSize.width) * 0.5, y: (screenSize.height-scanSize.height) * 0.5)
        let scanRect = CGRect(origin: scanOrigin, size: scanSize)
        // 需要交换 x、y 位置
        let scanPercentRect = CGRect(x: scanOrigin.y/screenSize.height, y: scanOrigin.x/screenSize.width, width: scanSize.height/screenSize.height, height: scanSize.width/screenSize.width)
        return (scanRect, scanPercentRect)
    }
}

extension SystemQRCodeViewController: AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        guard self.isReadMessage == false else {return}
        guard metadataObjects.count > 0 else {return}
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject else {return}
        let message = metadataObject.stringValue ?? "未读取到内容"
        
        let vc = UIAlertController(title: "二维码信息", message: message, preferredStyle: .alert)
        let sureAction = UIAlertAction(title: "确定", style: .default) { [weak self](_) in
            self?.isReadMessage = false
        }
        vc.addAction(sureAction)
        self.present(vc, animated: true, completion: nil)
        self.isReadMessage = true
    }
}
