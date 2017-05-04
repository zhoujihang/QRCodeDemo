//
//  ViewController.swift
//  QRCodeDemo
//
//  Created by 周际航 on 2017/5/4.
//  Copyright © 2017年 com.maramara. All rights reserved.
//

import UIKit


class ViewController: UIViewController {
    
    fileprivate lazy var tableView: UITableView = UITableView()
    fileprivate var qrcodeImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
}

// MARK: - 扩展 UI
private extension ViewController {
    func setup() {
        self.setupView()
        self.setupConstraints()
    }
    
    func setupView() {
        self.view.addSubview(self.tableView)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.showsVerticalScrollIndicator = false
        self.tableView.backgroundColor = UIColor.clear
    }
    
    func setupConstraints() {
        self.tableView.frame = UIScreen.main.bounds
    }
}

// MARK: - 扩展 UITableViewDelegate
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellID = "cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID) ?? UITableViewCell(style: .default, reuseIdentifier: cellID)
        cell.selectionStyle = .none
        
        var title = "\(indexPath.section) - \(indexPath.row)"
        
        if indexPath.row == 0 {
            title = "系统扫描二维码"
        } else if indexPath.row == 1 {
            title = "读取图片二维码"
        } else if indexPath.row == 2 {
            title = "生成二维码"
        }
        
        cell.textLabel?.text = title
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            self.test0()
        } else if indexPath.row == 1 {
            self.test1()
        } else if indexPath.row == 2 {
            self.test2()
        }
    }
}

// MARK: - 扩展 点击事件
private extension ViewController {
    
    func test0() {
        let vc = SystemQRCodeViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func test1() {
        self.openAlbum()
    }
    
    func test2() {
        let message = "生活不是眼前的苟且,还有诗和远方"
        let width: CGFloat = 300
        guard let image = QRCodeTool.generateQRCode(message: message, imageWidth: width) else {
            self.alert(title: "二维码生成失败", message: "")
            return
        }
        self.qrcodeImage = image
        
        let imageView = UIImageView()
        imageView.image = image
        imageView.bounds = CGRect(x: 0, y: 0, width: width, height: width)
        imageView.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        
        let backdropView = UIView()
        backdropView.backgroundColor = UIColor(white: 0, alpha: 0.1)
        backdropView.addSubview(imageView)
        
        self.view.addSubview(backdropView)
        backdropView.frame = UIScreen.main.bounds
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBackdropView(tap:)))
        backdropView.addGestureRecognizer(tap)
    }
    
    @objc func tapBackdropView(tap: UITapGestureRecognizer) {
        let vc = UIAlertController(title: "保存二维码吗？", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel) { _ in
            tap.view?.removeFromSuperview()
        }
        let sureAction = UIAlertAction(title: "保存", style: .default) { [weak self] (_) in
            if let image = self?.qrcodeImage {
                self?.savePictureToAlbum(image)
            }
            tap.view?.removeFromSuperview()
        }
        vc.addAction(cancelAction)
        vc.addAction(sureAction)
        self.present(vc, animated: true, completion: nil)
        
    }
}

// MARK: - 扩展 保存图片
private extension ViewController {
    func savePictureToAlbum(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(image:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafeRawPointer) {
        if let err = error {
            debugPrint("\(type(of: self)): \(#function) line:\(#line) \(err)")
        } else {
            debugPrint("\(type(of: self)): \(#function) line:\(#line) 图片保存成功")
        }
    }
}

// MARK: - 扩展 打开相册、识别二维码
private extension ViewController {
    func openAlbum() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            self.present(picker, animated: true, completion: nil)
        } else {
            debugPrint("\(type(of: self)): \(#function) line:\(#line) 无法打开相册")
        }
    }
    
    func alert(title: String, message: String) {
        let vc = UIAlertController(title: "二维码信息", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        vc.addAction(cancelAction)
        self.present(vc, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let originImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {return}
        let messages = QRCodeTool.detectQRCode(from: originImage)
        let message = "\(messages.count)个二维码：\n" + messages.joined(separator: "\n\n")
        self.alert(title: "二维码信息", message: message)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
