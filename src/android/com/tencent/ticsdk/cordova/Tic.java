package com.tencent.ticsdk.cordova;

import android.Manifest;
import android.annotation.TargetApi;
import android.app.Activity;
import android.app.Dialog;
import android.content.DialogInterface;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;

import com.tencent.TIMMessage;
import com.tencent.TIMUserStatusListener;
import com.tencent.boardsdk.board.WhiteboardView;
import com.tencent.ilivesdk.ILiveCallBack;
import com.tencent.ilivesdk.ILiveConstants;
import com.tencent.ilivesdk.ILiveSDK;
import com.tencent.ilivesdk.adapter.CommonConstants;
import com.tencent.ilivesdk.adapter.ContextEngine;
import com.tencent.ilivesdk.view.ILiveRootView;
import com.tencent.ticsdk.TICClassroomOption;
import com.tencent.ticsdk.TICManager;
import com.tencent.ticsdk.TICSDK;
import com.tencent.ticsdk.listener.IClassEventListener;
import com.tencent.ticsdk.listener.IClassroomIMListener;
import com.tencent.ticsdk.observer.ClassEventObservable;
import com.tencent.ticsdk.observer.ClassroomIMObservable;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;

import org.apache.cordova.PluginResult;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;



public class Tic extends CordovaPlugin implements IClassEventListener, IClassroomIMListener, TIMUserStatusListener {

    //    CallbackContext callbackContext;
    final static int REQUEST_CODE = 1;

    private boolean isRunning = false;
    private Dialog mainDialog = null;
    private Button handBtn = null;

    private int roomId = 0;
    private String teacherId = "";
    private String userId = "";
    private String userSig = "";
    private String role = "";
    private CallbackContext callbackContext = null;


//    @Override
//    protected void pluginInitialize() {
//        TICSDK.getInstance().initSDK(cordova.getActivity(), sdkappid);
//        checkCameraAndMicPermission();
//    }


    @Override
    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {

        this.callbackContext = callbackContext;

        if ("init".equals(action)) {
            int sdkappid = args.optInt(0);
            init(sdkappid);

        } else if ("join".equals(action)) {
            JSONObject options = args.optJSONObject(0);
            join(options);

        }

        return true;
    }

    private void init(final int sdkappid){
        TICSDK.getInstance().initSDK(cordova.getActivity(), sdkappid);
        checkCameraAndMicPermission();
    }


    private void join(JSONObject options){
        if(isRunning) return;

        userId = options.optString("userName");
        userSig = options.optString("userSig");
        roomId = options.optInt("roomId");
        role = options.optString("role");
        teacherId = options.optString("teacherId");

        this.login(userId, userSig);
        isRunning = true;
    }

    public void login(String userid, String userSig) {
        TICManager.getInstance().login(userid, userSig, new ILiveCallBack() {
            @Override
            public void onSuccess(Object data) {
                log("登录成功");
                onLoginSuccess();
            }

            @Override
            public void onError(String module, int errCode, String errMsg) {
                sendErrorMessage(errCode, errMsg);
                isRunning = false;
            }
        });
    }

    private void logout() {

        cordova.getActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_PORTRAIT);

        // this code is not executed
        TICManager.getInstance().quitClassroom(new ILiveCallBack() {
            @Override
            public void onSuccess(Object data) {
                log("退出成功");
            }

            @Override
            public void onError(String module, int errCode, String errMsg) {
                sendErrorMessage(errCode, errMsg);
            }
        });


        ClassEventObservable.getInstance().deleteObserver(this);
        ClassroomIMObservable.getInstance().deleteObserver(this);

        isRunning = false;
    }


    private void onLoginSuccess(){
        joinClassroom(roomId);
    }


    private void joinClassroom(int roomid){

        TICClassroomOption classroomOption = new TICClassroomOption()
                .setRoomId(roomid)
                .controlRole(role) //在参数对实时音视频的质量有较大影响，建议开发配置。；详情请移步：https://github.com/zhaoyang21cn/edu_project/blob/master/%E6%8E%A5%E5%85%A5%E6%8C%87%E5%BC%95%E6%96%87%E6%A1%A3/%E5%BC%80%E9%80%9A%E5%92%8C%E9%85%8D%E7%BD%AE%E8%85%BE%E8%AE%AF%E4%BA%91%E6%9C%8D%E5%8A%A1.md
                .autoSpeaker(true)
                .setRole(TICClassroomOption.Role.STUDENT)
                .autoCamera(true)
                .autoMic(false)
                .setEnableWhiteboard(false)
                .setClassroomIMListener(ClassroomIMObservable.getInstance())
                .setClassEventListener(ClassEventObservable.getInstance());


        TICManager.getInstance().joinClassroom(classroomOption, new ILiveCallBack() {
            @Override
            public void onSuccess(Object data) {
                onJoinRoomSuccess();
            }

            @Override
            public void onError(String module, int errCode, String errMsg) {
                onJoinRoomFailed(errCode, errMsg);
                isRunning = false;
            }
        });

    }


    // 设置mic
    private void setMic(boolean isEnable){
        TICManager.getInstance().enableMic(isEnable, new ILiveCallBack() {
            @Override
            public void onSuccess(Object data) {
                log("mic操作成功: " + data);
            }

            @Override
            public void onError(String module, int errCode, String errMsg) {
                sendErrorMessage(errCode, errMsg);
            }
        });
    }

    private void onJoinRoomSuccess(){
        cordova.getActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
        sendPluginResult();


        ClassEventObservable.getInstance().addObserver(this);
        ClassroomIMObservable.getInstance().addObserver(this);


        Activity activity = cordova.getActivity();

        // 添加主对话框
        mainDialog = new Dialog(activity, android.R.style.Theme_Black_NoTitleBar_Fullscreen);
        mainDialog.setContentView(getIdentifier("tic_main", "layout"));

        mainDialog.setOnCancelListener(new DialogInterface.OnCancelListener() {
            @Override
            public void onCancel(DialogInterface dialog) {
                logout();
            }
        });

        mainDialog.show();


        // 教师屏幕和各学员屏幕
        ILiveRootView teacherVideo = (ILiveRootView) findViewById("av_root_view");
        teacherVideo.initViews();
        teacherVideo.render(teacherId, 1);


        LinearLayout teacherVideoContainer = (LinearLayout) findViewById("av_root_view_container");

        if(Build.VERSION.SDK_INT >= 21){
            teacherVideoContainer.setClipToOutline(true);
        }

        createMemberVideos();


        // 添加举手按钮
        handBtn = (Button) findViewById("button");
        handBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                onHandButtonClick();
            }
        });

        // 添加关闭按钮
        Button closeBtn = (Button) findViewById("closeBtn");
        closeBtn.setOnClickListener(new View.OnClickListener(){
            @Override
            public void onClick(View v){
                mainDialog.cancel();
            }
        });


        HorizontalScrollView avRootScroll = (HorizontalScrollView) findViewById("av_root_scroll");

        // 添加左划按钮
        Button leftBtn = (Button) findViewById("leftBtn");
        leftBtn.setOnClickListener(new View.OnClickListener(){
            @Override
            public void onClick(View v){
                avRootScroll.arrowScroll(View.FOCUS_LEFT);
            }
        });

        // 添加右划按钮
        Button rightBtn = (Button) findViewById("rightBtn");
        rightBtn.setOnClickListener(new View.OnClickListener(){
            @Override
            public void onClick(View v){
                avRootScroll.arrowScroll(View.FOCUS_RIGHT);
            }
        });

        // 禁止学员操作白板
        WhiteboardView whiteboardview = (WhiteboardView) findViewById("whiteboardview");
        whiteboardview.setWhiteboardEnable(false);

        log("加入房间成功");
    }

    private void onJoinRoomFailed(int errCode, String errMsg){
        sendErrorMessage(errCode, errMsg);
    }


    private void createMemberVideos(){
        renderUserVideo(userId);

        ContextEngine contextEngine = ILiveSDK.getInstance().getContextEngine();
        List<String> userList = contextEngine.getVideoUserList(CommonConstants.Const_VideoType_Camera);

        for (String userId : userList) {
            if(userId.equals(teacherId)) continue;
            if(userId.equals(userId)) continue;
            renderUserVideo(userId);
        }
    }


    private void renderUserVideo(String userId){
        final LinearLayout layout = (LinearLayout) findViewById("av_root_container");

        final ILiveRootView videoView = new ILiveRootView(mainDialog.getContext());
        videoView.initViews();
        videoView.render(userId, 1);
        videoView.setDeviceRotation(180);
//        videoView.setBackground(getIdentifier("layout_bg", "drawable"));
//        videoView.setClipToOutline(true);


        layout.addView(videoView);

        layout.post(new Runnable(){
            public void run(){
                int height = layout.getHeight();
                LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(height, height);
                lp.rightMargin = 20;
                videoView.setLayoutParams(lp);
            }
        });
    }



    private void removeUserVideo(String userId){
        LinearLayout layout = (LinearLayout) findViewById("av_root_container");

        for (int i = 0; i < layout.getChildCount(); i++) {
            ILiveRootView video = (ILiveRootView) layout.getChildAt(i);
            if(video.getIdentifier().equals(userId)) layout.removeView(video);
        }

    }


    protected void checkCameraAndMicPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return;
        }

        List<String> permissionList = new ArrayList();
        if (!checkPermissionAudioRecorder()) {
            permissionList.add(Manifest.permission.RECORD_AUDIO);
        }

        if (!checkPermissionCamera()) {
            permissionList.add(Manifest.permission.CAMERA);
        }

        if (!checkPermissionStorage()) {
            permissionList.add(Manifest.permission.WRITE_EXTERNAL_STORAGE);
        }

        if (permissionList.size() < 1) {
            return;
        }
        String[] permissions = permissionList.toArray(new String[0]);
        ActivityCompat.requestPermissions(cordova.getActivity(), permissions, REQUEST_CODE);
    }

    private boolean checkPermissionAudioRecorder() {
        if (ContextCompat.checkSelfPermission(cordova.getActivity(), Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            return false;
        }
        return true;
    }

    private boolean checkPermissionCamera() {
        if (ContextCompat.checkSelfPermission(cordova.getActivity(), Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            return false;
        }
        return true;
    }

    private boolean checkPermissionStorage() {
        if (ContextCompat.checkSelfPermission(cordova.getActivity(), Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
            return false;
        }
        return true;
    }


    @Override
    public void onLiveVideoDisconnect(int errCode, String errMsg) {
        LOG.e("Tic", "onLiveVideoDisconnect");
    }

    @Override
    public void onClassroomDestroy(){
        LOG.e("Tic", "onClassroomDestroy");
        if(mainDialog != null) mainDialog.cancel();
    }

    @Override
    public void onMemberJoin(List<String> userList){
        LOG.e("Tic", "onMemberJoin");

        for (String newUserId : userList) {
            if(newUserId.equals(teacherId)) continue;
            if(newUserId.equals(userId)) continue;
            renderUserVideo(newUserId);
        }
    }

    @Override
    public void onMemberQuit(List<String> userList){
        LOG.e("Tic", "onMemberQuit");

        for (String quitUserId : userList) {
            if(quitUserId.equals(teacherId)) continue;
            if(quitUserId.equals(userId)) continue;
            removeUserVideo(quitUserId);
        }
    }

    @Override
    public void onRecordTimestampRequest(ILiveCallBack<Long> callBack){

    }


    @Override
    public void onRecvTextMsg(int type, String userId, String message) {
        if(userId.equals(teacherId)) onTeacherC2CMessage(message);
    }

    @Override
    public void onRecvCustomMsg(int type, String s, byte[] bytes) {
//        LinkedList<IClassroomIMListener> tmpList = new LinkedList<>(listObservers);
//        for (IClassroomIMListener listener : tmpList) {
//            listener.onRecvCustomMsg(type, s, bytes);
//        }
    }

    @Override
    public void onRecvMessage(TIMMessage message) {
//        LinkedList<IClassroomIMListener> tmpList = new LinkedList<>(listObservers);
//        for (IClassroomIMListener listener : tmpList) {
//            listener.onRecvMessage(message);
//        }
    }


    // 接收到老师的消息
    private void onTeacherC2CMessage(String message){
        if(message.equals("TIMCustomHandReplyYes")){
            sendC2CMessageToTeacher("TIMCustomHandRecOpenOk");
            setMic(true);
            handBtn.setText("正在发言");
        } else if(message.equals("TIMCustomHandReplyNo")){
            sendC2CMessageToTeacher("TIMCustomHandRecCloseOk");
            setMic(false);
            handBtn.setText("我要发言");
        }
    }

    // 发送消息给老师
    private void sendC2CMessageToTeacher(String message){
        TICManager.getInstance().sendTextMessage(teacherId, message, new ILiveCallBack() {
            @Override
            public void onSuccess(Object data) {
                log("发送消息成功");
            }

            @Override
            public void onError(String module, int errCode, String errMsg) {
                sendErrorMessage(errCode, errMsg);
            }
        });
    }

    // 学生举手
    private void onHandButtonClick(){
        if(!"我要发言".equals(handBtn.getText())) return;

        handBtn.setText("等待老师同意...");
        sendC2CMessageToTeacher("TIMCustomHand");
    }

    @Override
    public void onForceOffline() {

    }

    @Override
    public void onUserSigExpired() {

    }


    private void sendPluginResult(){
        PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
        pluginResult.setKeepCallback(true);
        callbackContext.sendPluginResult(pluginResult);
    }

    private void sendErrorMessage(int errCode, String errMsg){

        try {
            JSONObject obj = new JSONObject();

            obj.put("errId", errCode);
            obj.put("errMsg", errMsg);

            PluginResult pluginResult = new PluginResult(PluginResult.Status.ERROR, obj);
            pluginResult.setKeepCallback(true);
            callbackContext.sendPluginResult(pluginResult);

            log(errMsg);
        } catch (Exception e){
            log("返回插件信息失败");
        }

    }


    /**
     * findViewById
     *
     * @param viewId
     * @return
     */
    private View findViewById(String viewId) {
        return this.mainDialog.findViewById(getIdentifier(viewId, "id"));
    }

    /**
     * getIdentifier
     *
     * @param viewId
     * @param type
     * @return
     */
    private int getIdentifier(String viewId, String type) {
        Activity activity = cordova.getActivity();
        return activity.getResources().getIdentifier(viewId, type, activity.getPackageName());
    }

    private void log(String msg){
        Log.e("Tic", msg);
    }
}
