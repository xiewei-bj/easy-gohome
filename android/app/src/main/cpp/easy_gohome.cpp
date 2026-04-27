#include <jni.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <android/log.h>
#include <cstring>
#include <cstdlib>
#include <ctime>
#include "n2nOntun.h"

static JNIEnv *genv = nullptr;
static jobject callback = nullptr;
#define ANDROID_LOG_TAG "goGomeTunnel"

static int subnetMaskToBits(const char *subnetMask) {
    unsigned long mask = inet_addr(subnetMask);
    int bits = 0;
    while (mask) {
        bits += mask & 1;
        mask >>= 1;
    }
    return bits;
}

extern "C" {
    void _n2nExLog(char *str) {
        __android_log_print(ANDROID_LOG_INFO, ANDROID_LOG_TAG, "%s\n", str);
    }

    void vpnServiceProtect(int fd){
        __android_log_print(ANDROID_LOG_INFO, ANDROID_LOG_TAG,"vpnServiceProtect : fd = %d",  fd);
    }
}

static int tuntap_open(char *device_ip,           //tun上的ip
                       char *device_mask,         //tun上的掩码
                       int mtu) {                 //tun的MTU
    jclass jcls = genv->GetObjectClass(callback);
    jmethodID jmid = genv->GetMethodID(jcls,"opentun",
                                       "(Ljava/lang/String;II)I");
    jstring ipaddr = genv->NewStringUTF(device_ip);
    int mask = subnetMaskToBits(device_mask);
    return genv->CallIntMethod(callback,jmid,ipaddr,mask,mtu);
}
static int tuntap_read(int fd, unsigned char *buf, int len){
    int r = read(fd,buf,len);
    return r;
}
static int tuntap_write(int fd, unsigned char *buf, int len){
    return write(fd , buf,len);
}
static void tuntap_close(int fd){
    close(fd);
}


extern "C"
JNIEXPORT void JNICALL
Java_com_example_easy_1gohome_GohomeTunnelServer_stopTunnel(JNIEnv *env, jobject thiz) {
    // TODO: implement stopTunnel()
}

extern "C"
JNIEXPORT jint JNICALL
Java_com_example_easy_1gohome_GohomeTunnelServer_startTunnel(JNIEnv *env, jobject thiz,
                                                             jstring publicnode,
                                                             jstring community_name, jstring passwd,
                                                             jstring gwip, jobject a) {

    genv = env;
    callback = a;
    TunCb cb ;
    cb.tuntap_open = tuntap_open;
    cb.tuntap_read = tuntap_read;
    cb.tuntap_write = tuntap_write;
    cb.tuntap_close = tuntap_close;
    char* serveripport = (char*)env->GetStringUTFChars(publicnode,0);
    char* community = (char*)env->GetStringUTFChars(community_name,0);
    char* pk = (char*)env->GetStringUTFChars(passwd,0);
//    char* cdevicemac = (char*)env->GetStringUTFChars(jsdevicemac,0);

    unsigned char devicemac[DEVICE_MAC_LEN];
    devicemac[0]=0xff;
    devicemac[1]=0xfe;
    devicemac[2]=0xfd;
    srand((unsigned int)time(nullptr));
    devicemac[3] = (unsigned char)rand() % 120;
    devicemac[4] = (unsigned char)rand() % 120;
    devicemac[5] = (unsigned char)rand() % 120;


    _n2nmain(community, pk, serveripport,nullptr,&cb,devicemac);
    return 200;


    // TODO: implement startTunnel()
}