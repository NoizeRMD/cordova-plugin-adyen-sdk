import Adyen

// see https://docs.adyen.com/checkout/ios/drop-in
@objc(AdyenPlugin)
class AdyenPlugin: CDVPlugin {
    var command: CDVInvokedUrlCommand!
    var dropInComponent: DropInComponent!
    var lastPaymentResponse: PaymentMethodDetails!

    @objc(presentDropIn:)
    func presentDropIn(command: CDVInvokedUrlCommand) {
        self.lastPaymentResponse = nil
        self.command = command
        let obj: NSDictionary = command.arguments[0] as! NSDictionary

        let environment: String = obj["environment"] as? String ?? "test"
        let paymentMethodsResponse: String = obj["paymentMethodsResponse"] as! String
        let currencyCode: String = obj["currencyCode"] as! String
        let amount: Int = obj["amount"] as! Int

        self.commandDelegate.run(inBackground: {
            let configuration = DropInComponent.PaymentMethodsConfiguration()

            let paymentMethodsConfiguration: NSDictionary = obj["paymentMethodsConfiguration"] as! NSDictionary

            let card = paymentMethodsConfiguration["card"] as? NSDictionary
            if (card != nil) {
                configuration.card.publicKey = card!["publicKey"] as? String
                configuration.card.showsHolderNameField = card!["holderNameRequired"] as? Bool ?? false
                configuration.card.showsStorePaymentMethodField = card!["showStorePaymentField"] as? Bool ?? true
            }

            let applePay = paymentMethodsConfiguration["applepay"] as? NSDictionary
            if (applePay != nil) {
                let applePayConfig = applePay!["configuration"] as? NSDictionary
                if (applePayConfig != nil) {
                    configuration.applePay.merchantIdentifier = applePayConfig!["merchantIdentifier"] as? String
                }
            }

            let paymentMethods = (try? JSONDecoder().decode(PaymentMethods.self, from: Data(paymentMethodsResponse.utf8) ))!

            self.dropInComponent = DropInComponent(paymentMethods: paymentMethods, paymentMethodsConfiguration: configuration)
            self.dropInComponent.delegate = self
            self.dropInComponent.environment = "live".elementsEqual(environment) ? .live : .test
            // amount in cents
            self.dropInComponent.payment = Payment(amount: Payment.Amount(value: amount, currencyCode: currencyCode))

            DispatchQueue.main.async {
                self.viewController.present(self.dropInComponent.viewController, animated: true)
            }
        })
    }

    @objc(handleAction:)
    func handleAction(command: CDVInvokedUrlCommand) {
        // note: not running in background, because fi. the "redirect" type needs to perform actions on the UI thread
        let actionStr: String = command.arguments[0] as! String
        let action = (try? JSONDecoder().decode(Action.self, from: Data(actionStr.utf8)))!
        self.dropInComponent.handle(action)
    }

    @objc(dismissDropIn:)
    func dismissDropIn(command: CDVInvokedUrlCommand) {
        self.viewController.dismiss(animated: true)
        if (self.lastPaymentResponse == nil) {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId:self.command.callbackId)
        } else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: self.lastPaymentResponse.dictionaryRepresentation), callbackId:self.command.callbackId)
        }
    }
}

extension AdyenPlugin: DropInComponentDelegate {
    func didSubmit(_ data: PaymentComponentData, from component: DropInComponent) {
        self.lastPaymentResponse = data.paymentMethod
        let result: [String: Any] = ["action": "onSubmit", "data": self.lastPaymentResponse.dictionaryRepresentation]
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result)
        pluginResult!.keepCallback = NSNumber(true)
        self.commandDelegate.send(pluginResult, callbackId:self.command.callbackId)
    }

    func didProvide(_ data: ActionComponentData, from component: DropInComponent) {
        DispatchQueue.main.async {
            self.viewController.dismiss(animated: true)
        }
        let result: [String: Any] = ["action": "onAdditionalDetails", "data": data.paymentData]
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result)
        pluginResult!.keepCallback = NSNumber(true)
        self.commandDelegate.send(pluginResult, callbackId:self.command.callbackId)
    }

    // also invoked when cancelled (the close icon was pressed)
    func didFail(with error: Error, from component: DropInComponent) {
        DispatchQueue.main.async {
            self.viewController.dismiss(animated: true)
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "\(error)")
        self.commandDelegate.send(pluginResult, callbackId:command.callbackId)
    }
}
