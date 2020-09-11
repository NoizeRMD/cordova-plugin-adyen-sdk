import Adyen

// see https://docs.adyen.com/checkout/ios/drop-in
@objc(AdyenPlugin)
class AdyenPlugin: CDVPlugin {
    var command: CDVInvokedUrlCommand!
    var dropInComponent: DropInComponent!;
    var selectedPaymentMethod: PaymentMethodDetails!;

    @objc(presentDropIn:)
    func presentDropIn(command: CDVInvokedUrlCommand) {
        self.selectedPaymentMethod = nil;
        self.command = command
        let obj: NSDictionary = command.arguments[0] as! NSDictionary

        let environment: String = obj["environment"] as? String ?? "test"
//        let clientKey: String = obj["clientKey"] as! String
        let paymentMethodsResponse: String = obj["paymentMethodsResponse"] as! String
        let currencyCode: String = obj["currencyCode"] as! String
        let amount: Int = obj["amount"] as! Int

        self.commandDelegate.run(inBackground: {
            let configuration = DropInComponent.PaymentMethodsConfiguration()
//            configuration.card.publicKey = clientKey
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
        let actionStr: String = command.arguments[0] as! String

        self.commandDelegate.run(inBackground: {
            let action = (try? JSONDecoder().decode(Action.self, from: Data(actionStr.utf8)))!
            self.dropInComponent.handle(action)
        })
    }

    @objc(dismissDropIn:)
    func dismissDropIn(command: CDVInvokedUrlCommand) {
        self.viewController.dismiss(animated: true)
        if (self.selectedPaymentMethod == nil) {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId:self.command.callbackId)
        } else {
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: self.selectedPaymentMethod.dictionaryRepresentation), callbackId:self.command.callbackId)
        }
    }
}

extension AdyenPlugin: DropInComponentDelegate {
    func didSubmit(_ data: PaymentComponentData, from component: DropInComponent) {
        self.selectedPaymentMethod = data.paymentMethod;
        let result: [String: Any] = ["action": "onSubmit", "data": data.paymentMethod.dictionaryRepresentation]

        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: result)
        pluginResult!.keepCallback = NSNumber(true)

//             CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"ready":@(YES)}];

//             [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
//             self.viewController.dismiss(animated: true)
        self.commandDelegate.send(pluginResult, callbackId:self.command.callbackId)
    }

    func didProvide(_ data: ActionComponentData, from component: DropInComponent) {
        print("didProvide \(data)")
        DispatchQueue.main.async {
            self.viewController.dismiss(animated: true)
        }
        // TODO return the relevant result as the client needs to send that to the server
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data.paymentData)
        self.commandDelegate.send(pluginResult, callbackId:command.callbackId)
    }

    // also invoked when cancelled (the close icon was pressed)
    func didFail(with error: Error, from component: DropInComponent) {
        print("didFail: \(error), " + error.localizedDescription)
        DispatchQueue.main.async {
            self.viewController.dismiss(animated: true)
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "\(error)")
        self.commandDelegate.send(pluginResult, callbackId:command.callbackId)
    }
}
