package com.adyensdk.plugin;

import android.content.Intent;

import com.adyen.checkout.base.model.PaymentMethodsApiResponse;
import com.adyen.checkout.base.model.payments.Amount;
import com.adyen.checkout.core.api.Environment;
import com.adyen.checkout.dropin.DropIn;
import com.adyen.checkout.dropin.DropInConfiguration;
import com.adyen.checkout.sepa.SepaConfiguration;

import org.apache.cordova.*;
import org.json.JSONException;
import org.json.JSONObject;

public class AdyenPlugin extends CordovaPlugin {

  private static final String ACTION_PRESENT_DROP_IN = "presentDropIn";

  private static final String INTENT_ACTION_PRESENTDROPIN = "INTENT_ACTION_PRESENTDROPIN";

  private CallbackContext callbackContext;

  @Override
  public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {
    if (ACTION_PRESENT_DROP_IN.equals(action)) {
      presentDropIn(args, callbackContext);
      return true;
    } else {
      return false;
    }
  }

  private void presentDropIn(CordovaArgs args, CallbackContext callbackContext) throws JSONException {
    cordova.getThreadPool().execute(() -> {
      try {
        this.callbackContext = callbackContext;
        JSONObject options = args.getJSONObject(0);
        String environment = options.optString("environment", "test");
        int amountInCents = options.getInt("amountInCents");
        String currency = options.getString("currency");
        String paymentMethodsResponse = options.getString("paymentMethodsResponse");
        String clientKey = options.getString("clientKey");

        JSONObject json = new JSONObject(paymentMethodsResponse);
        PaymentMethodsApiResponse paymentMethodsApiResponse = PaymentMethodsApiResponse.SERIALIZER.deserialize(json);

        Intent intent = new Intent(cordova.getContext(), cordova.getActivity().getClass());
        intent.setAction("bla");
//        intent.setClassName("com.adyensdk.plugin", "AdyenPlugin");

        DropInConfiguration.Builder dropInConfigurationBuilder = new DropInConfiguration.Builder(cordova.getContext(), intent, AdyenPluginDropInService.class);
        dropInConfigurationBuilder.addSepaConfiguration(new SepaConfiguration.Builder(cordova.getContext()).build());
        Amount amount = new Amount();
        amount.setCurrency(currency);
        amount.setValue(amountInCents);
        dropInConfigurationBuilder.setAmount(amount);
        dropInConfigurationBuilder.setEnvironment("live".equals(environment) ? Environment.EUROPE : Environment.TEST);
        DropInConfiguration dropInConfiguration = dropInConfigurationBuilder.build();

        DropIn.startPayment(cordova.getContext(), paymentMethodsApiResponse, dropInConfiguration);

      } catch (JSONException e) {
        callbackContext.error(e.getMessage());
      }
    });
  }

  // TODO ff code van Moritz bekijken wat hun flow is..
  // TODO (documenteer / forceer vanuit plugin) dit wordt alleen aangeroepen als in AndroidManifest.xml dit op de activity staat: android:launchMode="singleInstance"
  public void onNewIntent(Intent intent) {
    super.onNewIntent(intent);
    if (INTENT_ACTION_PRESENTDROPIN.equals(intent.getAction())) {
      callbackContext.success();
    }
  }

  @Override
  public void onActivityResult(int requestCode, int resultCode, Intent intent) {
    super.onActivityResult(requestCode, resultCode, intent);
  }
}