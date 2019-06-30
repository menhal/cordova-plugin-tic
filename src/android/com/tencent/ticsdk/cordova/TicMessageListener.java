package com.tencent.ticsdk.cordova;

public interface TicMessageListener {
    void onCommand(String text);
    void onBroadcast(String fromUserId, String text);
}
