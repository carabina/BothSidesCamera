//
//  BothSidesView.swift
//  BothSidesCamera
//
//  Created by 永田大祐 on 2019/11/18.
//  Copyright © 2019 永田大祐. All rights reserved.
//
import UIKit
import AVFoundation

public class BothSidesView: UIView, UIGestureRecognizerDelegate {

    public var backCameraVideoPreviewView  = BothSidesPreviewView()
    public var frontCameraVideoPreviewView = BothSidesPreviewView()

    var aVCaptureMultiCamViewModel: BothSidesMultiCamViewModel?

    private var pinchGesture               : UIPinchGestureRecognizer?
    private var swipePanGesture            : UIPanGestureRecognizer?
    private var tapPanGesture              : UITapGestureRecognizer?
    private var doubleTapGestureRecognizer : UITapGestureRecognizer?
    private var orientation                : UIInterfaceOrientation = .unknown


    public init(backDeviceType: AVCaptureDevice.DeviceType,
                 frontDeviceType: AVCaptureDevice.DeviceType) {
        super.init(frame: .zero)

        aVCaptureMultiCamViewModel = BothSidesMultiCamViewModel()
        guard let session = self.aVCaptureMultiCamViewModel?.session else {
            print("AVCaptureMultiCamViewModel_session")
            return
        }

        self.frame = UIScreen.main.bounds
        backCameraVideoPreviewView.frame = self.frame
        frontCameraVideoPreviewView.frame = self.frame

        self.layer.addSublayer(backCameraVideoPreviewView.videoPreviewLayer)
        self.layer.addSublayer(frontCameraVideoPreviewView.videoPreviewLayer)

        backCameraVideoPreviewView.videoPreviewLayer.setSessionWithNoConnection(session)
        frontCameraVideoPreviewView.videoPreviewLayer.setSessionWithNoConnection(session)

        updateNormalizedPiPFrame()

        // builtInWideAngleCamera only
        aVCaptureMultiCamViewModel?.configureFrontCamera(frontCameraVideoPreviewView.videoPreviewLayer, deviceType: frontDeviceType)
        frontCameraVideoPreviewView.transform = frontCameraVideoPreviewView.transform.scaledBy(x: 0.3, y: 0.3)
        frontCameraVideoPreviewView.frame.origin.y -= UINavigationController.init().navigationBar.frame.height
        aVCaptureMultiCamViewModel?.configureMicrophone()

        aVCaptureMultiCamViewModel?.aModel?.recorderSet{ session.startRunning() }
        initSetting(self)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func pushFlash() { aVCaptureMultiCamViewModel?.pushFlash() }

    public func cameraStop() {
        guard let session = aVCaptureMultiCamViewModel?.session else {
            print("AVCaptureMultiCamViewModel_session")
            return
        }
        session.stopRunning()
    }

    public func cameraStart(completion: @escaping() -> Void) {

        guard let session = self.aVCaptureMultiCamViewModel?.session else {
            print("AVCaptureMultiCamViewModel_session")
            return
        }

        guard session.isRunning == true  else {
            session.startRunning()
            aVCaptureMultiCamViewModel?.aModel?.movieRecorder?.isRunning = false
            return
        }

        guard aVCaptureMultiCamViewModel?.aModel?.movieRecorder?.isRunning == true  else {
            aVCaptureMultiCamViewModel?.aModel?.recorderSet{ self.aVCaptureMultiCamViewModel?.aModel?.recordAction(completion: completion) }
            return
        }

        self.aVCaptureMultiCamViewModel?.aModel?.recordAction(completion: completion)
    }

    public func preViewSizeSet(orientation : UIInterfaceOrientation) -> Void {
        self.orientation = orientation
        oriantation { return }
        return
    }

    public func changeDviceType(backDeviceType : AVCaptureDevice.DeviceType,
                             frontDeviceType: AVCaptureDevice.DeviceType) {

        aVCaptureMultiCamViewModel?.changeDviceType()
        updateNormalizedPiPFrame()
        aVCaptureMultiCamViewModel?.configureBackCamera(backCameraVideoPreviewView.videoPreviewLayer, deviceType: backDeviceType)
    }
    
    private func oriantation(_ bind: ()->()) {
        switch aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition  {
        case .front:
            self.bringSubviewToFront(frontCameraVideoPreviewView)
            if orientation.isPortrait {
                self.frame = UIScreen.main.bounds
                transform = CGAffineTransform(rotationAngle: CGFloat.pi/180*1)
                backCameraVideoPreviewView.frame.origin.y = -UINavigationController.init().navigationBar.frame.height
            } else {
                self.frame = UIScreen.main.bounds
                backCameraVideoPreviewView.frame.origin.y = -UINavigationController.init().navigationBar.frame.height
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi/180*90)
            }
        case .back:
            self.bringSubviewToFront(backCameraVideoPreviewView)
            if orientation.isPortrait {
                self.frame = UIScreen.main.bounds
                transform = CGAffineTransform(rotationAngle: CGFloat.pi/180*1)
                frontCameraVideoPreviewView.frame.origin.y = -UINavigationController.init().navigationBar.frame.height
            } else {
                self.frame = UIScreen.main.bounds
                frontCameraVideoPreviewView.frame.origin.y = -UINavigationController.init().navigationBar.frame.height
                self.transform = CGAffineTransform(rotationAngle: CGFloat.pi/180*90)
            }
        default: break
        }
        bind()
    }

    private func initSetting(_ view: UIView? = nil) {

        swipePanGesture = UIPanGestureRecognizer(target: self, action:#selector(panTapped))
        view?.addGestureRecognizer(swipePanGesture ?? UIPanGestureRecognizer())

        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchSwipGesture))
        view?.addGestureRecognizer(pinchGesture ?? UIPinchGestureRecognizer())

        tapPanGesture = UITapGestureRecognizer(target: self, action:#selector(tapped))
        tapPanGesture?.numberOfTapsRequired = 1
        view?.addGestureRecognizer(tapPanGesture ?? UITapGestureRecognizer())
    }

    private func updateNormalizedPiPFrame() {

        let fullScreenVideoPreviewView: BothSidesPreviewView
        let pipVideoPreviewView: BothSidesPreviewView

        if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .back {
            fullScreenVideoPreviewView = frontCameraVideoPreviewView
            pipVideoPreviewView = backCameraVideoPreviewView
        } else if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
            fullScreenVideoPreviewView = backCameraVideoPreviewView
            pipVideoPreviewView = frontCameraVideoPreviewView
        } else {
            fatalError("Unexpected pip device position: \(String(describing: aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition))")
        }

        let pipFrameInFullScreenVideoPreview = pipVideoPreviewView.convert(pipVideoPreviewView.bounds, to: fullScreenVideoPreviewView)
        let normalizedTransform = CGAffineTransform(scaleX: 1.0 / fullScreenVideoPreviewView.frame.width, y: 1.0 / fullScreenVideoPreviewView.frame.height)
        aVCaptureMultiCamViewModel?.aModel?.normalizedPipFrame = pipFrameInFullScreenVideoPreview.applying(normalizedTransform)
    }

    @objc private func pinchSwipGesture(_ sender: UIPinchGestureRecognizer) {
        
        updateNormalizedPiPFrame()
        UIView.animate(withDuration: 0.5) {
            switch self.aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition {
            case .front:
                self.frontCameraVideoPreviewView.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
            case .back:
                self.backCameraVideoPreviewView.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
            default:
                break
            }
        }
    }

    @objc private func panTapped(sender: UIPanGestureRecognizer) {
        let position: CGPoint = sender.location(in: self)

        switch sender.state {
        case .changed:
            updateNormalizedPiPFrame()
            if orientation.isPortrait {
                if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
                    frontCameraVideoPreviewView.frame.origin.x = position.x - frontCameraVideoPreviewView.frame.width/2
                    frontCameraVideoPreviewView.frame.origin.y = position.y - frontCameraVideoPreviewView.frame.height/2
                } else {
                    backCameraVideoPreviewView.frame.origin.x = position.x - backCameraVideoPreviewView.frame.width
                    backCameraVideoPreviewView.frame.origin.y = position.y - backCameraVideoPreviewView.frame.height/2
                }
            } else {
                if aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition == .front {
                    frontCameraVideoPreviewView.frame.origin.x = position.x - frontCameraVideoPreviewView.frame.width/3
                    frontCameraVideoPreviewView.frame.origin.y = position.y - frontCameraVideoPreviewView.frame.height/2
                } else {
                    backCameraVideoPreviewView.frame.origin.x = position.x - backCameraVideoPreviewView.frame.width/3
                    backCameraVideoPreviewView.frame.origin.y = position.y - backCameraVideoPreviewView.frame.height/2
                }
            }
        default: break
        }
    }

    @objc private func tapped(sender: UIPanGestureRecognizer) { tappedLogic() }

    private func tappedLogic() {
        tapPanGesture = nil
        pinchGesture = nil
        doubleTapGestureRecognizer = nil
        CATransaction.begin()
        UIView.setAnimationsEnabled(false)
        CATransaction.setDisableActions(true)
        if orientation.isPortrait {
            switch aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition {
            case .front:
                frontCameraVideoPreviewView.transform = .identity
                frontCameraVideoPreviewView.frame = UIScreen.main.bounds
                backCameraVideoPreviewView.transform = backCameraVideoPreviewView.transform.scaledBy(x: 0.3, y: 0.3)
                aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .back
                self.bringSubviewToFront(backCameraVideoPreviewView)
                initSetting(backCameraVideoPreviewView)
            case .back:
                backCameraVideoPreviewView.transform = .identity
                backCameraVideoPreviewView.frame = UIScreen.main.bounds
                frontCameraVideoPreviewView.transform = frontCameraVideoPreviewView.transform.scaledBy(x: 0.3, y: 0.3)
                aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .front
                self.bringSubviewToFront(frontCameraVideoPreviewView)
                initSetting(frontCameraVideoPreviewView)
            default: break
            }
        } else {
            switch aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition {
            case .front:
                frontCameraVideoPreviewView.transform = .identity
                frontCameraVideoPreviewView.frame = backCameraVideoPreviewView.frame
                backCameraVideoPreviewView.frame.origin.y = -UINavigationController.init().navigationBar.frame.height
                backCameraVideoPreviewView.transform = backCameraVideoPreviewView.transform.scaledBy(x: 0.3, y: 0.3)
                aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .back
                self.bringSubviewToFront(backCameraVideoPreviewView)
                initSetting(backCameraVideoPreviewView)
            case .back:
                backCameraVideoPreviewView.transform = .identity
                backCameraVideoPreviewView.frame = frontCameraVideoPreviewView.frame
                frontCameraVideoPreviewView.frame.origin.y = -UINavigationController.init().navigationBar.frame.height
                frontCameraVideoPreviewView.transform = frontCameraVideoPreviewView.transform.scaledBy(x: 0.3, y: 0.3)
                aVCaptureMultiCamViewModel?.aModel?.pipDevicePosition = .front
                self.bringSubviewToFront(frontCameraVideoPreviewView)
                initSetting(frontCameraVideoPreviewView)
            default: break
            }
        }
        
        CATransaction.commit()
        UIView.setAnimationsEnabled(true)
        CATransaction.setDisableActions(false)
        updateNormalizedPiPFrame()
    }
}

