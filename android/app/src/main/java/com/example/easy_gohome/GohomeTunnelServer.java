package com.example.easy_gohome;

import android.annotation.SuppressLint;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.VpnService;
import android.os.IBinder;
import android.os.RemoteException;
import android.system.OsConstants;
import android.util.Log;
import java.util.Objects;


@SuppressLint("VpnServicePolicy")
public class GohomeTunnelServer extends VpnService {

    static{
        System.loadLibrary("easy_gohome");
    }
    private native void stopTunnel();
    private native int  startTunnel(String publicnode,String community_name,String passwd,String gwip,OpenTunCallback a);
    private Thread tunnelTh = null;
    public static final String VPN_TOOLS_LOG = "N2NServer";
    private final IBinder scpeServer = new aaaa();

    class aaaa extends Gohome.Stub {
        @Override
        public int startTunnelConnect(String publicnode, int port, String community_name, String passwd, String gwip) throws RemoteException {
            startTunnelThread(publicnode+":"+port,community_name,passwd,gwip);
            return 0;
        }

        @Override
        public void stopTunnelConnect() throws RemoteException {
            stopTunnelThread();
        }

        @Override
        public int getConnectStatus() throws RemoteException {
            return 0;
        }
    };


    @Override
    public IBinder onBind(Intent intent) {
        return scpeServer;
    }

    private void stopTunnelThread(){
        try {
            stopTunnel();
            if( tunnelTh != null ){
                tunnelTh.join();
                tunnelTh=null;
            }
        } catch (InterruptedException e) {
            Log.e(VPN_TOOLS_LOG,e.toString(),e);
        }
    }
    private void startTunnelThread(String publicnodeIpPort, String community_name, String passwd, String gwip){

        if ( tunnelTh != null){
            stopTunnelThread();
        }
        tunnelTh = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    Log.i(VPN_TOOLS_LOG, "tunnel Thread start");
                    startTunnel(publicnodeIpPort, community_name, passwd, gwip, new OpenTunCallback() {
                        @Override
                        public int opentun(String ipaddr, int netmask, int mtu) {
                            try {
                                return openN2nTun(ipaddr, netmask, mtu, gwip);
                            } catch (PackageManager.NameNotFoundException e) {
                                Log.e(VPN_TOOLS_LOG, "", e);
                            }
                            return -1;
                        }

                        @Override
                        public void vpnServiceProtect(int fd) {
                            boolean r = protect(fd);
                            Log.i(VPN_TOOLS_LOG, "vpnServiceProtect "+fd+" "+r);
                        }
                    });
                    Log.i(VPN_TOOLS_LOG, "tunnel Thread Stop");
                }catch (Exception e){
                    Log.e(VPN_TOOLS_LOG,"tunnel Thread Exception",e);
                }
            }
        },"tunnelThread");
        tunnelTh.start();
    }

    public int openN2nTun(String ipaddr, int netmask, int mtu, String gwip)
            throws PackageManager.NameNotFoundException {
        Builder builder = new Builder();
        builder.allowFamily(OsConstants.AF_INET);
        builder.addAddress(ipaddr,netmask);
        builder.addDnsServer(gwip);     //网关即是DNS
        //添加默认路由
        builder.addRoute("0.0.0.0", 0);

        //排除本app，本app的数据不走vpn隧道
        builder.addDisallowedApplication(getPackageName());

        builder.setSession("goHomeTunnel");
        builder.setMtu(mtu);
        try {
            return Objects.requireNonNull(builder.establish()).detachFd();
        }catch (Exception e){
            Log.e("ERROR",e.toString(),e);
        }
        return -1;
    }
}
