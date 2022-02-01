# Cordova plugin for the Adyen SDK

## Installation

```
$ cordova plugin add cordova-plugin-adyen-sdk
```

`Adyen.js` is brought in automatically.
It adds a global `Adyen` object which you can use to interact with the plugin.

## Usage

Check the [demo code](demo/index.html) for all the tricks in the book, or read on for some copy-pasteable samples.

Make sure to wait for `deviceready` before using any of these functions.

## API

### `presentDropIn`
This is the only method you'll need to implement.
Other plugin methods can be invoked from the callback function `onSubmit` below. 

```js
  var options = {
    clientKey: "clientKey",
    paymentMethodsResponse: {"paymentMethods":[]}, // the paymentMethods response from the server
    environment: "test", // or "live", default "test"
    currencyCode: "EUR",
    amount: 250, // in minor units (cents), so 250 in this case is "EUR 2,50"
    paymentMethodsConfiguration: {
      applepay: {
         countryCode,
         amount: "2.50", // amount in string
         configuration: {
           merchantName: "Product name",
           merchantIdentifier: "merchant.com.adyen.companyName.test"
         }
      },
    }, // configuration for payment methods (like card, applepay, googlepay)

    onSubmit: function (state) { // called after the user picks a payment method from the list
      // while this function is processing, keep the drop-in open
      console.log("onSubmit, paymentMethod picked: " + JSON.stringify(state.data));

      // simulating a server call here
      var fakeServerResponse = makePaymentDummy(state.data);

      if (fakeServerResponse.action) {
        // If the server response wants us to invoke an action, pass that to the plugin.
        // Note that the plugin will dismiss the drop-in control once the action has been handled by the user.
        Adyen.handleAction(fakeServerResponse.action);
      } else {
        // No further action required, so close the drop-in.
        Adyen.dismissDropIn();
      }
    },

    onAdditionalDetails: function (state) { // called after the user provided additional data
      // call your server here, no need to invoke the plugin afterwards
      console.log("onAdditionalDetails, state: " + JSON.stringify(state));
    }
  };

  Adyen.presentDropIn(options, onSuccess, onError);
```
