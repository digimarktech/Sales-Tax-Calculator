//
//  ViewController.swift
//  Sales Tax Calculator
//
//  Created by Marc Aupont on 3/5/17.
//  Copyright © 2017 Digimark Technical Solutions. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {
    
    @IBOutlet weak var dollarAmountTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var zipcodeFromAddressTextField: UITextField!
    
    @IBOutlet weak var taxRateLabel: UILabel!
    @IBOutlet weak var finalTotalLabel: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var zipcodeAloneTextField: UITextField!
    
    //This is the API key necessary to perform request against the API
    let API_KEY = "6xpCenZB3d%2B1gByZY8uTi5VUJH%2F8eKPHk3E%2B7l0YTYzfsNlzk4BmUtkJp00VxA4pvZFLVk%2BsHKd3kLr0pyTPzg%3D%3D"
    
    //This is the constant that I am using to store the first part of the URL that I am making the request against.
    //This is for the user selects to perform a query based on an Address
    let addressBaseUrl: String = "https://taxrates.api.avalara.com:443/address?country=usa&"
    
    //This is the constant that I am using to store the first part of the URL that I am making the request against.
    //This is for the user selects to perform a query based on an postal Code
    let postCodeBaseUrl: String = "https://taxrates.api.avalara.com:443/postal?country=usa&"
    
    //This is a property observer/ computer property. Essentially anytime I write a value to "taxRate", it will update the Label on the screen
    //to reflect the change
    var taxRate: Double = 0.0 {
        
        didSet {
            
            taxRateLabel.text = "Tax Rate: \(taxRate)%"
        }

    }
    
    //This is a property observer/ computer property. Essentially anytime I write a value to "finalTotal", it will update the Label on the screen
    //to reflect the change
    var finalTotal: String = "" {
        
        didSet {
            
            finalTotalLabel.text = "Total: \(finalTotal)"
        }
    }

    //This is a method that apple gives us that runs as soon as my App loads. In this method, I am making sure the taxRateLabel and finalTotalLabel
    //are set to an empty string. This is because in the actual implementation of the label, I have some default values stored in it to see
    //how it will look. Setting it equal to "" essentially makes it so that the text in the label doesnt show up when the app loads
    override func viewDidLoad() {
        super.viewDidLoad()
       
        taxRateLabel.text = ""
        finalTotalLabel.text = ""
        
        //this will allow me to run a function whenever a user taps on the screen
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
        
        //Loading spinner is true by default. This line stops it when app loads.
        activityIndicator.stopAnimating()
        
    }
    
    //This is a function I created to handle formatting my final result dollar amount so that is shows up as $X.XX
    func formatCurrency(dollarAmount: Double) -> String {
        
        let currencyFormatter = NumberFormatter()
        
        currencyFormatter.usesGroupingSeparator = true
        
        currencyFormatter.numberStyle = .currency
        
        let priceString = currencyFormatter.string(from: NSNumber(value: dollarAmount))
        
        return priceString!
    }
    
    //This is a function i created to handle displaying a prompt alert to the User
    func alert(title: String, message: String) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        
        alertController.addAction(okAction)
        
        present(alertController, animated: true)
        
    }
    
    //function to dismiss keyboard when user taps on the screen
    func dismissKeyboard() {
        
        view.endEditing(true)
    }

    //This function is tied to the "Calculate" button
    @IBAction func calculateButtonPressed(_ sender: Any) {
        
        //Show the loading spinner
        activityIndicator.startAnimating()
        
        //Search based on address
        if dollarAmountTextField.text != "" && addressTextField.text != "" && cityTextField.text != "" && stateTextField.text != "" && zipcodeFromAddressTextField.text != "" && zipcodeAloneTextField.text == "" {
            
            //The following 4 constants are used to store the data that we get from the various textFields on the screen
            //I am also making sure that I lowercase all the values coming in. It's not needed but I don't want any
            //conflicts when I send this data up to the API
            let address = addressTextField.text!.lowercased()
            let city = cityTextField.text!.lowercased()
            let state = stateTextField.text!.lowercased()
            let postal = zipcodeFromAddressTextField.text!
            
            //Here I am constructing my URL based on the values the user passed in
            let finalUrl = "\(addressBaseUrl)street=\(address)&city=\(city)&state=\(state)&postal=\(postal)"
            
            //Because we are making a web request, the URL needs to be encoded in a way that the server understands
            //Mainly i am making sure all spaces are replaced with %20
            let encodedURL = finalUrl.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
            
            //Now that I have a encodedURL, I am adding my apikey to the end of the request URL so I can have the final complete URL
            let completeURL = "\(encodedURL)&apikey=6xpCenZB3d%2B1gByZY8uTi5VUJH%2F8eKPHk3E%2B7l0YTYzfsNlzk4BmUtkJp00VxA4pvZFLVk%2BsHKd3kLr0pyTPzg%3D%3D"
            
            //Here I am using the Alamofire library to send a get request using my complete URL and working with the JSON response coming back
            Alamofire.request(completeURL).responseJSON { response in
                
                
                //debugPrint(response)
                
                
                //Based on the response we get back, download the data or display error message to the User. There is some room for improvement
                //here in handling multiple other cases
                if response.response?.statusCode == 400 {
                    
                    //display error unable to resolve address
                    self.alert(title: "Bad Address", message: "Please check your address and try again")
                    
                } else {
                    
                    if let responseDict = response.result.value  {
                        
                        let ratesDict = responseDict as! [String: Any]
                        
                        if let totalRate = ratesDict["totalRate"] as? Double {
                            
                            let dollarAmount = Double(self.dollarAmountTextField.text!)!
                            
                            let formattedDollarAmount = dollarAmount.formatTwoDecimalPlaces
                            
                            let taxAmount = ((formattedDollarAmount * totalRate) * 0.01).formatTwoDecimalPlaces
                            
                            let result = formattedDollarAmount + taxAmount
                            
                            let formattedResult = self.formatCurrency(dollarAmount: result)
                            
                            //Stop the loading spinner just before we display the data
                            self.activityIndicator.stopAnimating()
                            
                            self.taxRate = totalRate
                            
                            self.finalTotal = formattedResult
                            
                        }
                        
                    }
                    
                }
                
            }
            
            
        } else if zipcodeAloneTextField.text != "" && dollarAmountTextField.text != "" && addressTextField.text == "" && cityTextField.text == "" && stateTextField.text == "" && zipcodeFromAddressTextField.text == "" {
            
            let postalCode = zipcodeAloneTextField.text!
            
            let finalUrL = "\(postCodeBaseUrl)postal=\(postalCode)"
            
            let encodedURL = finalUrL.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!
            
            let completeURL = "\(encodedURL)&apikey=6xpCenZB3d%2B1gByZY8uTi5VUJH%2F8eKPHk3E%2B7l0YTYzfsNlzk4BmUtkJp00VxA4pvZFLVk%2BsHKd3kLr0pyTPzg%3D%3D"
            
            Alamofire.request(completeURL).responseJSON { response in
                
                
                if response.response?.statusCode == 400 {
                    
                    //display error unable to resolve address
                    self.alert(title: "Bad ZipCode", message: "Please check your zipcode and try again")
                    
                } else {
                    
                    if let responseDict = response.result.value  {
                        
                        let ratesDict = responseDict as! [String: Any]
                        
                        if let totalRate = ratesDict["totalRate"] as? Double {
                            
                            let dollarAmount = Double(self.dollarAmountTextField.text!)!
                            
                            let formattedDollarAmount = dollarAmount.formatTwoDecimalPlaces //Calling the formatTwoDecimalPlaces property on the dollar Amount
                            
                            let taxAmount = ((formattedDollarAmount * totalRate) * 0.01).formatTwoDecimalPlaces
                            
                            let result = formattedDollarAmount + taxAmount
                            
                            let formattedResult = self.formatCurrency(dollarAmount: result) //Formatting the finally result to put it in currency format
                            
                            self.activityIndicator.stopAnimating()
                            
                            self.taxRate = totalRate //Store the totalRate to the computed property taxRate, which will update the user interface
                            
                            self.finalTotal = formattedResult // Store the formattedResult to the finalTotal computed property, which will update the UI
                            
                        }
                        
                    }
                    
                }
                
            }
            
        } else {
            
            //display alert to user to pick between either address or zip code search
            self.alert(title: "Pick One", message: "Please perform search by Address OR Zipcode but not Both")
        }
        
        
    }
    
    //When the clear button is pressed, set all the labels and text fields to empty strings
    @IBAction func clearButtonPressed(_ sender: Any) {
        
        dollarAmountTextField.text = ""
        addressTextField.text = ""
        cityTextField.text = ""
        stateTextField.text = ""
        zipcodeFromAddressTextField.text = ""
        zipcodeAloneTextField.text = ""
        taxRateLabel.text = ""
        finalTotalLabel.text = ""
        
    }


}

//This section here is some added functionality I've added to the native Double Type
//Essentially it is a computed property that i can call on any Double value and it ensures that I only work with 2 decimal Places
extension Double {
    
    var formatTwoDecimalPlaces:Double {
        
        return Double(String(format: "%.2f", self))!
    }
}

