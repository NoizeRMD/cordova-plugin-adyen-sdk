package com.adyensdk.plugin;

import com.adyen.checkout.dropin.service.CallResult;
import com.adyen.checkout.dropin.service.DropInService;

import org.json.JSONObject;

public class AdyenPluginDropInService extends DropInService {
  @Override
  public CallResult makeDetailsCall(JSONObject jsonObject) {
    return new CallResult(CallResult.ResultType.FINISHED, "Great success!");
  }

  @Override
  public CallResult makePaymentsCall(JSONObject jsonObject) {
    JSONObject paymentMethod = jsonObject.getJSONObject("paymentMethod"); // TODO pass this to CDV callback
    return new CallResult(CallResult.ResultType.FINISHED, "Great success!!");
  }
}
