//
//  CameraView.swift
//  swiftChallenge
//
//  Created by Ximena Tobias on 07/06/25.
//

import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        return CameraViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
