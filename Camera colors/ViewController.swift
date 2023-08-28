//
//  ViewController.swift
//  Camera colors
//
//  Created by Ярослав Вербило on 2023-05-29.
//



import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var imageView: UIImageView!
    var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.delegate = self
        view.addSubview(scrollView)
        
        imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
        
        let takePhotoButton = UIButton(type: .system)
        takePhotoButton.setTitle("Take Photo", for: .normal)
        takePhotoButton.addTarget(self, action: #selector(takePhotoButtonTapped), for: .touchUpInside)
        takePhotoButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(takePhotoButton)
        
        NSLayoutConstraint.activate([
            takePhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            takePhotoButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        imageView.addGestureRecognizer(tapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        scrollView.addGestureRecognizer(pinchGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.maximumNumberOfTouches = 1
        imageView.addGestureRecognizer(panGesture)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateZoomScale()
    }
    
    func updateZoomScale() {
        guard let image = imageView.image else {
            return
        }
        
        let scrollViewSize = scrollView.bounds.size
        let imageSize = image.size
        
        let widthScale = scrollViewSize.width / imageSize.width
        let heightScale = scrollViewSize.height / imageSize.height
        let minScale = min(widthScale, heightScale)
        
        scrollView.minimumZoomScale = minScale
        scrollView.maximumZoomScale = 4.0
        scrollView.zoomScale = minScale
        
        let scaledImageSize = CGSize(width: imageSize.width * minScale, height: imageSize.height * minScale)
        imageView.frame = CGRect(origin: .zero, size: scaledImageSize)
        
        let verticalInset = max(0, (scrollViewSize.height - scaledImageSize.height) / 2)
        let horizontalInset = max(0, (scrollViewSize.width - scaledImageSize.width) / 2)
        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }
    
    @objc func takePhotoButtonTapped() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: imageView)
        let convertedLocation = convertToImageCoordinate(location)
        
        guard let image = imageView.image,
              let color = image.getPixelColor(at: convertedLocation) else {
            return
        }
        
        let rgbCode = color.rgbCode
        let alert = UIAlertController(title: "Color Info", message: rgbCode, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else {
            return
        }
        
        if gesture.state == .changed {
            let pinchCenter = CGPoint(x: gesture.location(in: view).x - view.bounds.midX,
                                      y: gesture.location(in: view).y - view.bounds.midY)
            let transform = view.transform.translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: gesture.scale, y: gesture.scale)
                .translatedBy(x: -pinchCenter.x, y: -pinchCenter.y)
            
            view.transform = transform
            gesture.scale = 1.0
        }
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else {
            return
        }
        
        if gesture.state == .changed {
            let translation = gesture.translation(in: view.superview)
            view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
            gesture.setTranslation(.zero, in: view.superview)
        }
    }
    
    func convertToImageCoordinate(_ point: CGPoint) -> CGPoint {
        guard let image = imageView.image else {
            return .zero
        }
        
        let imageSize = image.size
        let imageViewSize = imageView.bounds.size
        let scale = max(imageSize.width / imageViewSize.width, imageSize.height / imageViewSize.height)
        
        let offsetX = (imageViewSize.width - imageSize.width / scale) / 2.0
        let offsetY = (imageViewSize.height - imageSize.height / scale) / 2.0
        
        let convertedX = (point.x - offsetX) * scale
        let convertedY = (point.y - offsetY) * scale
        
        return CGPoint(x: convertedX, y: convertedY)
    }
    
    // UIImagePickerControllerDelegate methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
            updateZoomScale()
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

extension UIImage {
    func getPixelColor(at point: CGPoint) -> UIColor? {
            guard let cgImage = self.cgImage,
                  let pixelData = cgImage.dataProvider?.data,
                  let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
                return nil
            }
            
            let width = cgImage.width
            let height = cgImage.height
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * width
            
            let pixelInfo = Int(point.y) * bytesPerRow + Int(point.x) * bytesPerPixel
            
            guard pixelInfo < width * height * bytesPerPixel else {
                return nil
            }
            
            let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            
            let red = CGFloat(data[pixelInfo]) / 255.0
            let green = CGFloat(data[pixelInfo + 1]) / 255.0
            let blue = CGFloat(data[pixelInfo + 2]) / 255.0
            let alpha = CGFloat(data[pixelInfo + 3]) / 255.0
            
            let color = UIColor(
                cgColor: CGColor(
                    colorSpace: colorSpace,
                    components: [red, green, blue, alpha]
                )!
            )
            
            return color
        }
}

extension UIColor {
    var rgbCode: String {
        guard let components = self.cgColor.components else {
            return ""
        }
        
        let red = Int(components[0] * 255)
        let green = Int(components[1] * 255)
        let blue = Int(components[2] * 255)
        
        return String(format: "RGB: %d, %d, %d", red, green, blue)
    }
}
