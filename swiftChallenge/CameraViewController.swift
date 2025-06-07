//
//  CameraViewController.swift
//  swiftChallenge
//
//  Created by Ximena Tobias on 07/06/25.
//

import UIKit
import AVFoundation
import CoreML


class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupCaptureButton()
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: backCamera),
              captureSession.canAddInput(input) else {
            print("Cannot access back camera")
            return
        }
        
        captureSession.addInput(input)
        
        photoOutput = AVCapturePhotoOutput()
        guard captureSession.canAddOutput(photoOutput) else {
            print("Cannot add photo output")
            return
        }
        captureSession.addOutput(photoOutput)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func setupCaptureButton() {
        let captureButton = UIButton(frame: CGRect(x: view.bounds.midX - 35, y: view.bounds.height - 100, width: 70, height: 70))
        captureButton.layer.cornerRadius = 35
        captureButton.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        captureButton.layer.borderColor = UIColor.black.cgColor
        captureButton.layer.borderWidth = 2
        captureButton.addTarget(self, action: #selector(takePicture), for: .touchUpInside)
        view.addSubview(captureButton)
    }
    
    @objc func takePicture() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Capture Delegate
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Could not get image")
            return
        }
        
        predictFood(from: image)
    }
    
    // MARK: - ML Prediction
    func predictFood(from image: UIImage) {
        let model = SeeFood()
        
        // Make sure the input size matches your model input, e.g., 224x224
        guard let resizedBuffer = pixelBuffer(from: image, size: CGSize(width: 299, height: 299)) else {
            print("Failed to convert image to pixel buffer")
            return
        }
        
        guard let result = try? model.prediction(image: resizedBuffer) else {
            print("Prediction failed")
            return
        }
        
        let confidence = result.foodConfidence[result.classLabel]! * 100.0
        let message = "\(result.classLabel) – \(String(format: "%.2f", confidence))%"
        
        DispatchQueue.main.async {
            self.showResultAlert(message: message)
        }
    }

    
    func showResultAlert(message: String) {
        let alert = UIAlertController(title: "Prediction", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func pixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(size.width),
                                         Int(size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        else {
            return nil
        }
        
        UIGraphicsPushContext(context)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        UIGraphicsPopContext()
        
        CVPixelBufferUnlockBaseAddress(buffer, [])
        
        return buffer
    }

}
