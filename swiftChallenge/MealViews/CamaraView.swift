//
//  CamaraView.swift
//  swiftChallenge
//
//  Created by Victoria Marin on 07/06/25.
//

import SwiftUI
import Vision
import UIKit
import AVFoundation
import CoreML

// MARK: - Camera View (UIViewControllerRepresentable)
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onImageCaptured = { image in
            onImageCaptured(image)
            dismiss()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

// MARK: - Camera View Controller
class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onImageCaptured: ((UIImage) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupCaptureButton()
        setupCloseButton()
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    func setupCaptureButton() {
        let captureButton = UIButton(frame: CGRect(x: view.bounds.midX - 35, y: view.bounds.height - 120, width: 70, height: 70))
        captureButton.layer.cornerRadius = 35
        captureButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        captureButton.layer.borderColor = UIColor.systemGreen.cgColor
        captureButton.layer.borderWidth = 3
        captureButton.addTarget(self, action: #selector(takePicture), for: .touchUpInside)
        view.addSubview(captureButton)
    }
    
    func setupCloseButton() {
        let closeButton = UIButton(frame: CGRect(x: 30, y: 60, width: 44, height: 44))
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        closeButton.layer.cornerRadius = 22
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeCamera), for: .touchUpInside)
        view.addSubview(closeButton)
    }
    
    @objc func takePicture() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    @objc func closeCamera() {
        dismiss(animated: true)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Could not get image")
            return
        }
        
        onImageCaptured?(image)
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
