# swift_suscripcion_renovable_applestore
Archivos necesarios para agregar a su proyecto y poder usar la suscripción renovable de app store

Estos archivos fueron parte de un proyecto y contiene:

- OpcionesCompraViewController: Una clase que se adjunta a un view controller para mostrar los tipos de suscripcion renovables establecidos en itune store

- SubscriptionService: Maneja las notificaciones que se emiten en el proceso de pago. Se ingresa el id del producto de las suscripciones renovables. El valor de currentSessionId permite validar si ya realizo un pago y puede acceder a la informacion

- PaidSuscription: Maneja la informacion de: la fecha de compra, fecha que termina la suscripcion y el id del producto

- Session: Maneja el id de la sesion

- Subscription: Maneja la informacion del tipo de suscripcion

Pasos para integrarlo

1) En el view controller que se desea validar si pago o no para los fines convenientes, agregar la siguiente linea de codigo


        
        guard SubscriptionService.shared.currentSessionId != nil,
            SubscriptionService.shared.hasReceiptData else {
                
                //codigo para mostrar una alerta indicando que debe pagar
                showPagoAlerta()
                
                return
        }
        
        
    //ejemplo de alerta
    func showPagoAlerta()
    {
        
        alert = UIAlertController(title: "AVISO", message: "", preferredStyle: UIAlertControllerStyle.alert)
        let hogan = NSMutableAttributedString.init(string: "Inserte mensaje sobre ser usuario premium aquí.")
        hogan.addAttribute( NSAttributedStringKey(rawValue: "NSFontAttributeName"), value: UIFont.systemFont(ofSize: 50.0), range: NSMakeRange(24, 11) )
        alert?.setValue(hogan, forKey: "attributedMessage")
        
        alert?.addAction(UIAlertAction(title: "Pagar", style: UIAlertActionStyle.default, handler: {
            action in
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "OpcionesCompra") as! OpcionesCompraViewController
            controller.protocolo = self
            
            var lista : [ItemPago] = []
            let options = SubscriptionService.shared.options
            for option in options!
            {
                
                let item = ItemPago(titulo: option.product.localizedTitle,
                                    descripcion: option.product.localizedDescription,
                                    precio: Float(truncating: option.product.price) )
                lista.append( item )
            }
            controller.lista = lista
            
            self.present(controller, animated: true, completion: nil)
            
        }))
        
        alert?.addAction(UIAlertAction(title: "Cancelar", style: UIAlertActionStyle.default, handler: {
            action in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert!, animated: true, completion: nil)
        
    }
    
        
        
2) Agregar en Appdelegate


extension AppDelegate: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue,
                      updatedTransactions transactions: [SKPaymentTransaction]) {
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                handlePurchasingState(for: transaction, in: queue)
            case .purchased:
                handlePurchasedState(for: transaction, in: queue)
            case .restored:
                handleRestoredState(for: transaction, in: queue)
            case .failed:
                handleFailedState(for: transaction, in: queue)
            case .deferred:
                handleDeferredState(for: transaction, in: queue)
            }
        }
        
    }
    
    func handlePurchasingState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        print("User is attempting to purchase product id: \(transaction.payment.productIdentifier)")
    }
    
    func handlePurchasedState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        print("User purchased product id: \(transaction.payment.productIdentifier)")
        
        queue.finishTransaction(transaction)
        SubscriptionService.shared.uploadReceipt { (success) in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: SubscriptionService.purchaseSuccessfulNotification, object: nil)
            }
        }
        
    }
    
    func handleRestoredState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        print("Purchase restored for product id: \(transaction.payment.productIdentifier)")
        
        queue.finishTransaction(transaction)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: SubscriptionService.restoreSuccessfulNotification, object: nil)
        }
    }
    
    func handleFailedState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        print("Purchase failed for product id: \(transaction.payment.productIdentifier)")
        
        queue.finishTransaction(transaction)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: SubscriptionService.purchaseFailedNotification, object: nil)
        }
    }
    
    func handleDeferredState(for transaction: SKPaymentTransaction, in queue: SKPaymentQueue) {
        print("Purchase deferred for product id: \(transaction.payment.productIdentifier)")
        
        queue.finishTransaction(transaction)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: SubscriptionService.purchaseDeferredNotification, object: nil)
        }
        
    }
    
}



3) En la funcion de Appdelegate


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        ...
        SubscriptionService.shared.loadSubscriptionOptions()

        ...
    }
    
