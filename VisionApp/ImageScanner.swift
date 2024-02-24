
import SwiftUI
import AVFoundation

struct ImageScanner: View {
    public let session = AVCaptureSession()
    
        let videoDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualWideCamera], mediaType: .video, position: .front).devices.first
        do {
            deviceInput = try AVCaptureDeviceInput(device: videoDevice!)
        } catch {
            print("Could not create video device input: \(error)")
            return nil
        }
        
        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        
        guard session.canAddInput(deviceInput) else{
            session.commitConfiguration()
            return nil
        }
        
        session.addInput(videoDevice)
        
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
            
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            print("Could not add video data output to the session")
            session.commitConfiguration()
            return nil
        }
        
        if session.canAddOutput(AVCaptureVideoDataOutput){
            session.canAddOutput(AVCaptureVideoDataOutput)
            
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            videoDataOutput.setSampleBufferDelegate(self, queue: AVCaptureVideoDataOutputQueue)
        } else{
            print("Unable to add video data")
            session.commitConfiguration()
            return nil
        }
    
    let captureConnection = videoDataOutput.connection(with: .video)
    func captureConnection;?.isEnabled = true
    do {
        try  videoDevice!.lockForConfiguration()
        let dimensions = CMVideoFormatDescriptionGetDimensions((videoDevice?.activeFormat.formatDescription)!)
        bufferSize.width = CGFloat(dimensions.width)
        bufferSize.height = CGFloat(dimensions.height)
        videoDevice!.unlockForConfiguration()
    } catch {
        print(error)
    }
    
    previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    rootLayer = previewView.layer
    previewLayer.frame = rootLayer.bounds
    rootLayer.addSublayer(previewLayer)
    
    func getExifOrientation() -> CGImagePropertyOrientation {
        let curDeviceOrientation = UIDevice.current.orientation
        let exifOrientation: CGImagePropertyOrientation

        switch curDeviceOrientation {
        case .portraitUpsideDown:  // Device oriented vertically, home button on the top
            exifOrientation = .left
        case .landscapeLeft:       // Device oriented horizontally, home button on the right
            exifOrientation = .upMirrored
        case .landscapeRight:      // Device oriented horizontally, home button on the left
            exifOrientation = .down
        case .portrait:            // Device oriented vertically, home button on the bottom
            exifOrientation = .up
        default:
            exifOrientation = .up
        }

        return exifOrientation
    }
    
    func createVisionModel(from modelURL: URL, searchQuery: String) throws -> VNCoreMLModel {
        // Load the Core ML model from the specified URL
        let mlModel = try MLModel(contentsOf: modelURL)
        
        // Create a Vision model from the Core ML model
        let visionModel = try VNCoreMLModel(for: mlModel)
        
        // Create a Vision request for object recognition
        let objectRecognition = VNCoreMLRequest(model: visionModel) { request, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error during object recognition request: \(error)")
                    return
                }
                
                guard let results = request.results else {
                    print("No results found.")
                    return
                }
                
                // Process the results and trigger a Google search
                if let firstResult = results.first as? YourResultType {
                    let searchQuery = "\(firstResult)"
                    performAutomaticSearch(query: searchQuery)
                } else {
                    print("No suitable results found for automatic search.")
                }
            }
        }
        
        // Return the created Vision model
        return visionModel
    }

    func performAutomaticSearch(query: String) {
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("Failed to encode search query string.")
            return
        }
        
        
        let searchURLString = "https://www.google.com/search?q=\(encodedQuery)"
        guard let searchURL = URL(string: searchURLString) else {
            print("Failed to create search URL.")
            return
        }
        
       
        UIApplication.shared.open(searchURL, options: [:], completionHandler: nil)
    }

    
    
    
    var body: some View {
        Text("Welcome to SScan")
    }
}

#Preview {
    ImageScanner()
}
