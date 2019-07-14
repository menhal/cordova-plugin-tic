package com.tencent.ticsdk.cordova;
import com.tencent.TIMMessage;
import com.tencent.ilivesdk.ILiveCallBack;
import com.tencent.ticsdk.TICManager;
import com.tencent.ticsdk.listener.IClassroomIMListener;

import org.apache.cordova.LOG;
import org.json.JSONException;
import org.json.JSONObject;


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

    public void sendBroadcast(String message, String userId){
        if("".equals(message)) return;

        String jsonString = this.toJson("chat", message, userId);

        TICManager.getInstance().sendTextMessage(null, jsonString, new ILiveCallBack() {
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


    @Override
    public void onRecvTextMsg(int type, String fromUserId, String text) {

        if(fromUserId.equals(teacherId) && text.equals("TIMCustomHandReplyYes")){

            listener.onCommand(text);

        } else if (fromUserId.equals(teacherId) && text.equals("TIMCustomHandReplyYes")){

            listener.onCommand(text);

        } else {

            JSONObject message = this.getJsonObject(text);

            String msgType = message.optString("type");
            String uid = message.optString("uid");
            String msg = message.optString("msg");
            String integral = message.optString("integral");
            String addIntegral = message.optString("addIntegral");

            if(msgType.equals("laud")){

                listener.onScore(uid, Integer.parseInt(integral), Integer.parseInt(addIntegral), msg);

            } else {

                listener.onBroadcast(fromUserId, text);

            }
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

    private JSONObject getJsonObject(String json){

        try {

            JSONObject jsonObject = new JSONObject(json);
            return jsonObject;

        } catch (JSONException e){
            return null;
        }

    }

    private String toJson(String type, String msg, String userId){


        try{
            JSONObject jsonObject = new  JSONObject();
            jsonObject.put("type", type);
            jsonObject.put("msg", msg);
            jsonObject.put("uid", userId);
            jsonObject.put("integral", "");
            jsonObject.put("addIntegral", "");

            return jsonObject.toString();

        } catch (JSONException e){
            return "";
        }

    }
}
