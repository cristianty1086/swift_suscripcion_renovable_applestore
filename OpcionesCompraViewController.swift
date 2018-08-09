//
//  OpcionesCompraViewController.swift
//  FTips
//
//  Created by Cristian Tinoco Yurivilca on 6/08/18.
//  Copyright © 2018 Ana Laura Rosas Cabello. All rights reserved.
//

import Foundation
import UIKit

class OpcionesCompraViewController: UIViewController {
 
    @IBOutlet weak var txtTitulo1: UILabel!
    @IBOutlet weak var txtPrecio1: UILabel!
    @IBOutlet weak var txtDescripcion1: UILabel!
    @IBOutlet weak var view1: UIView!
    
    @IBOutlet weak var txtTitulo2: UILabel!
    @IBOutlet weak var txtPrecio2: UILabel!
    @IBOutlet weak var txtDescripcion2: UILabel!
    @IBOutlet weak var view2: UIView!
    
    @IBOutlet weak var txtTitulo3: UILabel!
    @IBOutlet weak var txtPrecio3: UILabel!
    @IBOutlet weak var txtDescripcion3: UILabel!
    @IBOutlet weak var view3: UIView!
    
    var lista : [ItemPago] = []
    
    var protocolo : ProtocoloPago?
     
    @IBAction func onBackPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(onSubscribe), name: SubscriptionService.purchaseSuccessfulNotification, object: nil )
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(onFailed), name: SubscriptionService.purchaseFailedNotification, object: nil )
        
        let locale = Locale.current
        let currencySymbol = locale.currencySymbol!
        
        txtTitulo1.text = lista[ 0 ].titulo
        txtDescripcion1.text = lista[ 0 ].descripcion
        let pp1 = currencySymbol + " " + String(format: "%.2f", lista[ 0 ].precio )
        txtPrecio1.text = pp1
        
        txtTitulo2.text = lista[ 1 ].titulo
        txtDescripcion2.text = lista[ 1 ].descripcion
        let pp2 = currencySymbol + " " + String(format: "%.2f", lista[ 1 ].precio )
        txtPrecio2.text = pp2
        
        txtTitulo3.text = lista[ 2 ].titulo
        txtDescripcion3.text = lista[ 2 ].descripcion
        let pp3 = currencySymbol + " " + String(format: "%.2f", lista[ 2 ].precio )
        txtPrecio3.text = pp3
         
    }
    
    @IBAction func onBoton1(_ sender: Any) {
        guard let option = SubscriptionService.shared.options?[0] else { return }
        SubscriptionService.shared.purchase(subscription: option)
        self.view1.layer.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.25).cgColor
    }
    
    @IBAction func onBoton2(_ sender: Any) {
        guard let option = SubscriptionService.shared.options?[1] else { return }
        SubscriptionService.shared.purchase(subscription: option)
        self.view2.layer.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.25).cgColor
    }
    
    @IBAction func onBoton3(_ sender: Any) {
        guard let option = SubscriptionService.shared.options?[2] else { return }
        SubscriptionService.shared.purchase(subscription: option)
        self.view3.layer.backgroundColor = UIColor(displayP3Red: 1, green: 1, blue: 1, alpha: 0.25).cgColor
    }
    
    
    /*
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lista.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let locale = Locale.current
        let currencySymbol = locale.currencySymbol!
        //let currencyCode = locale.currencyCode!
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellPago", for: indexPath) as! CellPago
        cell.titulo.text = lista[ indexPath.row ].titulo
        cell.descripcion.text = lista[ indexPath.row ].descripcion
        let pp = currencySymbol + " " + String(format: "%.2f", lista[ indexPath.row ].precio )
        cell.precio.text = pp
        
        return cell
        
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let option = SubscriptionService.shared.options?[indexPath.row] else { return }
        SubscriptionService.shared.purchase(subscription: option)
        
        
    }
    */
    
    @objc func onSubscribe(_ notification: Notification) {
        
        self.protocolo?.osSuccess(viewcontroller: self)
    }
    
    @objc func onFailed(_ notification: Notification) {
        
        self.protocolo?.onError(viewcontroller: self, error: notification.debugDescription)
    }
    
}
