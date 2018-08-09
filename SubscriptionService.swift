//
//  SubscriptionService.swift
//  FTips
//
//  Created by Ana Laura Rosas Cabello on 31/07/18.
//  Copyright © 2018 Ana Laura Rosas Cabello. All rights reserved.
//

import Foundation
import StoreKit


public enum Result<T> {
    case failure(SelfieServiceError)
    case success(T)
}

public enum SelfieServiceError: Error {
    case missingAccountSecret
    case invalidSession
    case noActiveSubscription
    case other(Error)
}

public typealias SessionId = String

public typealias UploadReceiptCompletion = (_ result: Result<(sessionId: String, currentSubscription: PaidSubscription?)>) -> Void

class SubscriptionService: NSObject {
    
    
    private let itcAccountSecret = "ea1efb602067436aaa470d14e6a31630"
    
    private var sessions = [SessionId: Session]()
    
    var currentSubscription: PaidSubscription?
    
    static let sessionIdSetNotification = Notification.Name("SubscriptionServiceSessionIdSetNotification")
    static let optionsLoadedNotification = Notification.Name("SubscriptionServiceOptionsLoadedNotification")
    static let restoreSuccessfulNotification = Notification.Name("SubscriptionServiceRestoreSuccessfulNotification")
    static let purchaseSuccessfulNotification = Notification.Name("SubscriptionServicePurchaseSuccessfulNotification")
    static let purchaseFailedNotification = Notification.Name("SubscriptionServiceFaillSuccessfulNotification")
    static let purchaseDeferredNotification = Notification.Name("SubscriptionServiceDeferredSuccessfulNotification")
    
    
    static let shared = SubscriptionService()
    let simulatedStartDate: Date
    
    
    override init() {
        let persistedDateKey = "RWSSimulatedStartDate"
        if let persistedDate = UserDefaults.standard.object(forKey: persistedDateKey) as? Date {
            simulatedStartDate = persistedDate
        } else {
            let date = Date().addingTimeInterval(-30) // 30 second difference to account for server/client drift.
            UserDefaults.standard.set(date, forKey: "RWSSimulatedStartDate")
            
            simulatedStartDate = date
        }
    }
    
    var hasReceiptData: Bool {
        return loadReceipt() != nil
    }
    
    var currentSessionId: String? {
        didSet {
            NotificationCenter.default.post(name: SubscriptionService.sessionIdSetNotification, object: currentSessionId)
        }
    }
    
    //var currentSubscription: PaidSubscription?
    
    var options: [Subscription]? {
        didSet {
            NotificationCenter.default.post(name: SubscriptionService.optionsLoadedNotification, object: options)
        }
    }
    
    func loadSubscriptionOptions() {
        // TODO: Initiate request for products
        
        let allAccessMonthly = "ftips_onemonth"
        let allAccessYear = "ftips_oneyear"
        let allAccessSixMonths = "ftips_sixmonths"
        
        let productIDs = Set([allAccessMonthly, allAccessYear, allAccessSixMonths])
        
        let request = SKProductsRequest.init(productIdentifiers: productIDs)
        request.delegate = self
        request.start()
    }
    
    func purchase(subscription: Subscription) {
        // TODO: Create payment
        
        let payment = SKPayment(product: subscription.product)
        SKPaymentQueue.default().add(payment)
    }
    
    func restorePurchases() {
        // TODO: Initiate restore
    }
    
    
    func uploadReceipt(completion: ((_ success: Bool) -> Void)? = nil) {
        if let receiptData = loadReceipt() {
            
            
            SubscriptionService.shared.upload(receipt: receiptData) { [weak self] (result) in
                guard let strongSelf = self else { return }
                
                switch result {
                case .success(let result):
                    strongSelf.currentSessionId = result.sessionId
                    strongSelf.currentSubscription = result.currentSubscription
                    completion?(true)
                case .failure(let error):
                    print("🚫 Receipt Upload Failed: \(error)")
                    completion?(false)
                }
                
            }
            
            
        }
    }
    
    
    private func loadReceipt() -> Data? {
        // Load the receipt data from the device
        guard let url = Bundle.main.appStoreReceiptURL else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            return data
        } catch {
            print("Error loading receipt data: \(error.localizedDescription)")
            return nil
        }
        
    }
    
    
    /// Trade receipt for session id
    public func upload(receipt data: Data, completion: @escaping UploadReceiptCompletion) {
        let body = [
            "receipt-data": data.base64EncodedString(),
            "password": itcAccountSecret
        ]
        let bodyData = try! JSONSerialization.data(withJSONObject: body, options: [])
        
        let url = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        
        let task = URLSession.shared.dataTask(with: request) { (responseData, response, error) in
            if let error = error {
                completion(.failure(.other(error)))
            } else if let responseData = responseData {
                let json = try! JSONSerialization.jsonObject(with: responseData, options: []) as! Dictionary<String, Any>
                let session = Session(receiptData: data, parsedReceipt: json)
                self.sessions[session.id] = session
                let result = (sessionId: session.id, currentSubscription: session.currentSubscription)
                completion(.success(result))
            }
        }
        
        task.resume()
    }
    
    
}

extension SubscriptionService: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        
        let invalidProducts = response.invalidProductIdentifiers
        
        options = response.products.map {
            Subscription(product: $0)
            
        }
        
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        if request is SKProductsRequest {
            print("Subscription Options Failed Loading: \(error.localizedDescription)")
        }
    }
}
