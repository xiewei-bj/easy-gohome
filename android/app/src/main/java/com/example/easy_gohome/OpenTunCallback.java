package com.example.easy_gohome;

public interface OpenTunCallback {
    int opentun(String ipaddr,int netmask,int mtu);
    void vpnServiceProtect(int fd);
}
