// Gohome.aidl
package com.example.easy_gohome;

// Declare any non-default types here with import statements

interface Gohome {
    /**
     * Demonstrates some basic types that you can use as parameters
     * and return values in AIDL.
     */
    int   startTunnelConnect(String publicnode,int port,String community_name,String passwd, String gwip);
    void  stopTunnelConnect();
    int   getConnectStatus();
}