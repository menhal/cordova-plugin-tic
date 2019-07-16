package com.tencent.ticsdk.cordova;

public interface TicMessageListener {
    void onCommand(String text);
    void onBroadcast(String truename, String text);
    void onScore(String userId, int integral, int addIntegral, String msg);
}
