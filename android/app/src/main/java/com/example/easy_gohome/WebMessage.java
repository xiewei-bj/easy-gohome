package com.example.easy_gohome;

import android.os.RemoteException;
import android.util.Log;
import android.webkit.JavascriptInterface;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Objects;

public class WebMessage {
    private Gohome gohome = null;
    public WebMessage(Gohome gohome){
        this.gohome = gohome;
    }
    @JavascriptInterface
    public boolean connect(String msg) {
        try {
            JSONObject msgjs = new JSONObject(msg);
            JSONObject supjs = msgjs.getJSONObject("supernode");
            String ip = supjs.getString("ipaddr");
            int port = supjs.getInt("port");
            String group = supjs.getString("groupname");
            String pass = supjs.getString("passwd");
            String gw   = supjs.getString("gateway");

            gohome.startTunnelConnect(ip,port,group,pass,gw);
        } catch (Exception e) {
            Log.e("err", Objects.requireNonNull(e.getMessage()));
            return false;
        }
        return true;
    }

    @JavascriptInterface
    public boolean disconnect() {
        try {
            gohome.stopTunnelConnect();
        } catch (RemoteException e) {
            Log.e("err", Objects.requireNonNull(e.getMessage()));
            return false;
        }
        return true;
    }

}
