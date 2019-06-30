package com.tencent.ticsdk.cordova;
import com.tencent.TIMMessage;
import com.tencent.ilivesdk.ILiveCallBack;
import com.tencent.ticsdk.TICManager;
import com.tencent.ticsdk.listener.IClassroomIMListener;

import org.apache.cordova.LOG;


public class TicMessageHandler implements IClassroomIMListener{

    private TicMessageListener listener = null;
    private String teacherId = "";

    public void setTeacherId(String teacherId){
        this.teacherId = teacherId;
    }

    public void setMessageListener(TicMessageListener listener){
        this.listener = listener;
    }

    public void sendCommand(String message){
        TICManager.getInstance().sendTextMessage(teacherId, message, new ILiveCallBack() {
            @Override
            public void onSuccess(Object data) {
                LOG.i("Tic", "发送消息成功");
            }

            @Override
            public void onError(String module, int errCode, String errMsg) {
                LOG.i("Tic", "发送消息失败");
            }
        });
    }

    public void sendBroadcast(String message){
        if("".equals(message)) return;

        TICManager.getInstance().sendTextMessage(null, message, new ILiveCallBack() {
            @Override
            public void onSuccess(Object data) {
                LOG.i("Tic", "发送消息成功");
            }

            @Override
            public void onError(String module, int errCode, String errMsg) {
                LOG.i("Tic", "发送消息失败");
            }
        });
    }

    public void sendTextMessage(String message){

    }

    @Override
    public void onRecvTextMsg(int type, String fromUserId, String text) {
        if(fromUserId.equals(teacherId) && type == 1)
            listener.onCommand(text);
        else {
            listener.onBroadcast(fromUserId, text);
        }
    }

    @Override
    public void onRecvCustomMsg(int type, String fromUserId, byte[] data) {

    }

    @Override
    public void onRecvMessage(TIMMessage message) {

        String userId = message.getSender();
        LOG.i("Tic", "onRecvMessage");
//        listener.onBroadcast(message);
    }
}
