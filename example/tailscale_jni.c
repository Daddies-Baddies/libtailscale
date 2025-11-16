#include <jni.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "../tailscale.h"

JNIEXPORT jlong JNICALL Java_EchoServer_tailscaleNew(JNIEnv *env, jobject obj) {
    return (jlong)tailscale_new();
}

JNIEXPORT jint JNICALL Java_EchoServer_tailscaleSetEphemeral(JNIEnv *env, jobject obj, jlong ts, jint ephemeral) {
    return tailscale_set_ephemeral((tailscale)ts, ephemeral);
}

JNIEXPORT jint JNICALL Java_EchoServer_tailscaleUp(JNIEnv *env, jobject obj, jlong ts) {
    return tailscale_up((tailscale)ts);
}

JNIEXPORT jlong JNICALL Java_EchoServer_tailscaleListen(JNIEnv *env, jobject obj, jlong ts, jstring network, jstring address) {
    const char *network_str = (*env)->GetStringUTFChars(env, network, NULL);
    const char *address_str = (*env)->GetStringUTFChars(env, address, NULL);

    tailscale_listener ln;
    int result = tailscale_listen((tailscale)ts, network_str, address_str, &ln);

    (*env)->ReleaseStringUTFChars(env, network, network_str);
    (*env)->ReleaseStringUTFChars(env, address, address_str);

    return result == 0 ? (jlong)ln : 0;
}

JNIEXPORT jlong JNICALL Java_EchoServer_tailscaleAccept(JNIEnv *env, jobject obj, jlong listener) {
    tailscale_conn conn;
    int result = tailscale_accept((tailscale_listener)listener, &conn);
    return result == 0 ? (jlong)conn : 0;
}

JNIEXPORT jint JNICALL Java_EchoServer_tailscaleCloseConn(JNIEnv *env, jobject obj, jlong conn) {
    return close((int)conn);
}

JNIEXPORT jint JNICALL Java_EchoServer_tailscaleCloseListener(JNIEnv *env, jobject obj, jlong listener) {
    return close((int)listener);
}

JNIEXPORT jint JNICALL Java_EchoServer_tailscaleClose(JNIEnv *env, jobject obj, jlong ts) {
    tailscale_close((tailscale)ts);
    return 0;
}

JNIEXPORT jstring JNICALL Java_EchoServer_tailscaleErrmsg(JNIEnv *env, jobject obj, jlong ts) {
    char errmsg[256];
    tailscale_errmsg((tailscale)ts, errmsg, sizeof(errmsg));
    return (*env)->NewStringUTF(env, errmsg);
}
