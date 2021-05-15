//
//  ViewController.swift
//  WhatFlower
//
//  Created by janelle myers on 5/8/21.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var label: UILabel!
    
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    //set image picker object
    let imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .camera
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //or editedImage
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
        
        //imageView.image = userPickedImage
        
        //convert to core in able to use Vision
       guard let convertedImage = CIImage(image: userPickedImage)else {
            fatalError("could not convert to CI Image")
        }
        //pass image to detect func
        detect(image: convertedImage)
    }
        //dismiss
        
        imagePicker.dismiss(animated: true, completion: nil)
    }
   
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        //open camera
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    func detect(image: CIImage){
        //create object, tap into model property
        guard let model = try? VNCoreMLModel(for: FlowerClassifier(configuration: MLModelConfiguration()).model) else {
            fatalError("Failed to load Core ML model")
        }
        
        //create request with completion handler (request, error results)
        let request = VNCoreMLRequest(model: model) { (request, error) in
            //process data, classification
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("model failed to process image")
            }
            DispatchQueue.main.async {
                self.navigationItem.title = classification.identifier.capitalized
                self.requestWikiInfo(flowerName: classification.identifier)
                
            }
        }
                
//specify image you want classified

let handler = VNImageRequestHandler(ciImage: image)
do {
  try handler.perform([request])
}
catch {
    print(error)
}


    }
    
    func requestWikiInfo(flowerName: String){
        
        let parameters : [String:String] = [
         "format" : "json",
         "action" : "query",
            //if you were to add image from wiki
         "prop" : "extracts|pageimages",
         "exintro" : "",
         "explaintext" : "",
         "titles" : flowerName,
            "indexpageids" : "",
         "redirects" : "1",
        "pithumbsize" : "500",
         ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            
            if response.result.isSuccess {
                print("Got wiki info")
               
                //type json, turns categories to strings
                let flowerJSON: JSON = JSON(response.result.value!)
                //pull up ID path, swiftyjson converts to string
                let pageID = flowerJSON["query"]["pageids"][0].stringValue
                
                //path to description
                let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                //update text
                self.label.text = flowerDescription
                //pull url
                let flowerImageURL = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                
                self.imageView.sd_setImage(with: URL(string:flowerImageURL))
            }
        }
    }
}
