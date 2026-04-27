package com.example.easy_gohome;

import android.annotation.SuppressLint;
import android.content.ComponentName;
import android.content.Intent;
import android.content.ServiceConnection;
import android.net.VpnService;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.activity.EdgeToEdge;
import androidx.activity.result.ActivityResult;
import androidx.activity.result.ActivityResultCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

public class MainActivity extends AppCompatActivity {
    private com.example.easy_gohome.Gohome gohome =null;
    private ActivityResultLauncher<Intent> vpnPermiss=null;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);



        vpnPermiss = registerForActivityResult(
                new ActivityResultContracts.StartActivityForResult(), new ActivityResultCallback<ActivityResult>() {
                    @Override
                    public void onActivityResult(ActivityResult result) {}
                });

        bindTunnelServer();
        try {
            requestVpnConnectPermission();
        }catch (Exception e){
            Log.e("ERROR",e.toString(), e);
        }
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });
    }

    public void requestVpnConnectPermission() {
        Intent intent = VpnService.prepare(getApplicationContext());
        if ( intent != null ) {
            vpnPermiss.launch(intent);
        }
    }

    private void bindTunnelServer() {
        Intent intent = new Intent();
        intent.setPackage(getPackageName());
        boolean r = bindService( intent,new ServiceConnection() {

            @Override
            public void onServiceConnected(ComponentName name, IBinder service) {
                gohome = Gohome.Stub.asInterface(service);
                initWebView(findViewById(R.id.webview),gohome);
            }
            @Override
            public void onServiceDisconnected(ComponentName name) {

            }
        }, BIND_AUTO_CREATE);
        Log.i("bind","bindserver "+r);
    }


    @SuppressLint("SetJavaScriptEnabled")
    private void initWebView(WebView w,Gohome gohome) {
        w.getSettings().setJavaScriptEnabled(true);
        // 设置可以支持缩放
        w.getSettings().setSupportZoom(true);
        // 设置出现缩放工具
        w.getSettings().setBuiltInZoomControls(true);
        //扩大比例的缩放
        w.getSettings().setUseWideViewPort(true);
        //自适应屏幕
        w.getSettings().setLoadWithOverviewMode(true);
        w.getSettings().setDomStorageEnabled(true);
        //不缓存
        w.getSettings().setCacheMode(WebSettings.LOAD_DEFAULT);

        w.clearCache(true);
        //如果不设置WebViewClient，请求会跳转系统浏览器
        w.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                //返回false，意味着请求过程里，不管有多少次的跳转请求（即新的请求地址），均交给webView自己处理，这也是此方法的默认处理
                //返回true，说明你自己想根据url，做新的跳转，比如在判断url符合条件的情况下，我想让webView加载http://ask.csdn.net/questions/178242
                return false;
            }

        });
        w.setWebChromeClient(new WebChromeClient(){
            @Override
            public boolean onConsoleMessage(android.webkit.ConsoleMessage consoleMessage) {
                // 使用 LogCat 将 console.log 打印的日志显示在 Android Studio 控制台
                Log.d("chrome:",consoleMessage.sourceId()+":"+consoleMessage.lineNumber()+": "+consoleMessage.message() );
                return true;
            }
        });
        w.addJavascriptInterface(new WebMessage(gohome), "webMessage");
        w.loadUrl("file:///android_asset/index.html");
        w.onResume();
    }
}