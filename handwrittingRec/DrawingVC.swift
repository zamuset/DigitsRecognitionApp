//
//  ViewController.swift
//  handwrittingRec
//
//  Created by Samuel Chavez on 25/04/18.
//  Copyright © 2018 Samuel Chavez. All rights reserved.
//

import UIKit
import CoreML
import Vision

class DrawingVC: UIViewController {

    @IBOutlet weak var drawingIV: UIImageView!
    @IBOutlet weak var predictionLbl: UILabel!
    
    var lastPoint = CGPoint.zero
    var swiped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false
        drawingIV.image = nil
        if let touch = touches.first {
            lastPoint = touch.location(in: drawingIV)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        if let touch = touches.first {
            let currentPoint = touch.location(in: drawingIV)
            drawLine(fromPoint: lastPoint, toPoint: currentPoint)
            
            lastPoint = currentPoint
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if swiped == false {
            drawLine(fromPoint: lastPoint, toPoint: lastPoint)
        }
    }
    
    func drawLine(fromPoint: CGPoint, toPoint: CGPoint) {
        UIGraphicsBeginImageContext(drawingIV.frame.size)
        let context = UIGraphicsGetCurrentContext()
        
        drawingIV.image?.draw(in: CGRect(x: 0, y: 0, width: drawingIV.frame.size.width, height: drawingIV.frame.size.height))
        
        context?.move(to: CGPoint(x: fromPoint.x, y: fromPoint.y))
        context?.addLine(to: CGPoint(x: toPoint.x, y: toPoint.y))
        
        context?.setLineCap(.round)
        context?.setLineWidth(10.0)
        context?.setStrokeColor(UIColor.white.cgColor)
        context?.setBlendMode(.normal)
        context?.strokePath()
        
        drawingIV.image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }

    @IBAction func predictBtnPressed(_ sender: Any) {
        guard let predictionImage = drawingIV.image else { return }
        makePrediction(image(with: predictionImage, scaletTo: CGSize(width: 28.0, height: 28.0)))
    }
    
    func makePrediction(_ image: UIImage) {
        guard let model = try? VNCoreMLModel(for: Handwriting().model) else { return }
        let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
        guard let ciImage = CIImage(image: image) else { return }
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            debugPrint(error)
        }
    }
    
    func resultsMethod(request: VNRequest, error: Error?) {
        guard let results = request.results,
            let resultsArray = results[0] as? VNCoreMLFeatureValueObservation,
            let multiArrayVal = resultsArray.featureValue.multiArrayValue else { return }
        var prediction: NSNumber = 0
        var compare: NSNumber = 0
        var atIndex = 0
        var i = 0
        
        while i < multiArrayVal.count {
            compare = multiArrayVal[i]
            if compare.floatValue > prediction.floatValue {
                prediction = compare
                atIndex = i
            }
            i += 1
        }
        predictionLbl.text = "Digit may be: \(atIndex)"
        debugPrint(results)
    }
    
    func image(with image: UIImage, scaletTo newSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        drawingIV.image = newImage
        return newImage ?? UIImage()
    }
}
