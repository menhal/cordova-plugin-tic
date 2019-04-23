package com.tencent.ticsdk.cordova;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.app.FragmentTransaction;
import android.content.DialogInterface;
import android.content.pm.PackageManager;
import android.nfc.Tag;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.Toast;

import com.tencent.TIMMessage;
import com.tencent.TIMUserStatusListener;
import com.tencent.ilivesdk.ILiveCallBack;
import com.tencent.ilivesdk.ILiveConstants;
import com.tencent.ilivesdk.ILiveSDK;
import com.tencent.ilivesdk.adapter.CommonConstants;
import com.tencent.ilivesdk.adapter.ContextEngine;
import com.tencent.ilivesdk.core.ILiveRoomManager;
import com.tencent.ilivesdk.view.ILiveRootView;
import com.tencent.ticsdk.TICClassroomOption;
import com.tencent.ticsdk.TICManager;
import com.tencent.ticsdk.TICSDK;
import com.tencent.ticsdk.listener.IClassEventListener;
import com.tencent.ticsdk.listener.IClassroomIMListener;
import com.tencent.ticsdk.observer.ClassEventObservable;
import com.tencent.ticsdk.observer.ClassroomIMObservable;
import com.tencent.ticsdk.observer.UserStatusObservable;
import com.tencent.ticsdk.views.LivingVideoView;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

import io.ionic.starter.R;


public class Tic extends CordovaPlugin implements IClassEventListener, IClassroomIMListener, TIMUserStatusListener {

    //    CallbackContext callbackContext;
    final static int REQUEST_CODE = 1;

    boolean isRunning = false;
    Dialog mainDialog = null;
    ILiveRootView videoViews[] = new ILiveRootView[0];

    @Override
    protected void pluginInitialize() {
        int sdkappid = 1400204887;
        TICSDK.getInstance().initSDK(cordova.getContext(), sdkappid);
        checkCameraAndMicPermission();
    }


    @Override
    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {
        if(isRunning) return false;

        JSONObject options = args.getJSONObject(0);

        isRunning = true;
        this.join();
        return true;
    }

    private void join(){
        String userId = "Android_trtc_01";
        String userSig = "eJxlj11PgzAYhe-5FYRbjL60fJp4oZUMFkGZM8arhkGpnQpNKXOb8b*7oVESz*3z5JycD8M0TWt5c39aVlU3tJrqnWSWeW5aYJ38QSlFTUtNsar-QbaVQjFaNpqpETqe5yGAqSNq1mrRiB-jsq1Vd2jUSlcUnInY1y90XPtucgEQuGEYTBXBR5jFDyQtyAJntw4n6ypp5nY55H5OwA4RDPF6OdM6zdlsE5CneeQWKX8866*lJjbPVsn73St6Fskq9PlCFNyt5N7eYgzRPgnjK-diMqnFG-u9FmE-iPwJ3TDVi64dBQSO5yAMx1jGp-EFtt1e2A__";

        this.login(userId, userSig);
    }

    public void login(String userid, String userSig) {
        TICManager.getInstance().login(userid, userSig, new ILiveCallBack() {
            @Override
            public void onSuccess(Object data) {
                LOG.e("Tic", "登录成功");
                onLoginSuccess();
            }

            @Override
            public void onError(String module, int errCode, String errMsg) {
                LOG.e("Tic", "登录失败："+ errMsg);
                isRunning = false;
            }
        });
    }

    private void logout() {
        // this code is not executed
        TICManager.getInstance().quitClassroom(new ILiveCallBack() {
            @Override
            public void onSuccess(Object data) {
                LOG.e("Tic", "退出成攻");
            }

            @Override
            public void onError(String module, int errCode, String errMsg) {
                LOG.e("Tic", "退出失败");
            }
        });


        ClassEventObservable.getInstance().deleteObserver(this);
        ClassroomIMObservable.getInstance().deleteObserver(this);

        isRunning = false;
    }


    private void onLoginSuccess(){
        joinClassroom(3);
    }


    private void joinClassroom(int roomid){

        TICClassroomOption classroomOption = new TICClassroomOption()
                .setRoomId(roomid)
                .controlRole("ed640") //在参数对实时音视频的质量有较大影响，建议开发配置。；详情请移步：https://github.com/zhaoyang21cn/edu_project/blob/master/%E6%8E%A5%E5%85%A5%E6%8C%87%E5%BC%95%E6%96%87%E6%A1%A3/%E5%BC%80%E9%80%9A%E5%92%8C%E9%85%8D%E7%BD%AE%E8%85%BE%E8%AE%AF%E4%BA%91%E6%9C%8D%E5%8A%A1.md
                .autoSpeaker(false)
                .setRole(TICClassroomOption.Role.STUDENT)
                .autoCamera(true)
                .autoMic(false)
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


        TICManager.getInstance().enableCamera(ILiveConstants.FRONT_CAMERA, true, new ILiveCallBack() {
            @Override
            public void onSuccess(Object data) {
                Log.i("Tic", "enableCamera#onSuccess: " + data);
            }

            @Override
            public void onError(String module, int errCode, String errMsg) {
                Log.i("Tic", "enableCamera#onError: errCode = " + errCode + "  description " + errMsg);
            }
        });
    }

    private void onJoinRoomSuccess(){
        ClassEventObservable.getInstance().addObserver(this);
        ClassroomIMObservable.getInstance().addObserver(this);


        Activity activity = cordova.getActivity();

        mainDialog = new Dialog(activity, android.R.style.Theme_Black_NoTitleBar_Fullscreen);
        mainDialog.setContentView(R.layout.tic_main);

        mainDialog.setOnCancelListener(new DialogInterface.OnCancelListener() {
            @Override
            public void onCancel(DialogInterface dialog) {
                logout();
            }
        });

        mainDialog.show();


        ILiveRootView teacherVideo = (ILiveRootView) mainDialog.findViewById(R.id.av_root_view);
        teacherVideo.initViews();
        teacherVideo.render("Web_trtc_01", 1);


        createMemberVideos();



        Button button = mainDialog.findViewById(R.id.button);
        button.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {

            }
        });

        LOG.e("Tic", "加入房间成功");
    }

    private void onJoinRoomFailed(int errCode, String errMsg){
        LOG.e("Tic", "加入房间失败:"+errMsg);
    }


    private void createMemberVideos(){

        ContextEngine contextEngine = ILiveSDK.getInstance().getContextEngine();
        LinearLayout layout = mainDialog.findViewById(R.id.av_root_container);
        layout.removeAllViewsInLayout();


        renderUserVideo(layout, "Android_trtc_01");


        for (String userId : contextEngine.getVideoUserList(CommonConstants.Const_VideoType_Camera)) {
            if(userId.equals("Web_trtc_01")) continue;
            renderUserVideo(layout, userId);
        }

    }


    private void renderUserVideo(LinearLayout layout, String userId){
        ILiveRootView videoView = new ILiveRootView(mainDialog.getContext());
        videoView.initViews();
        videoView.render(userId, 1);


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
        if (ContextCompat.checkSelfPermission(cordova.getContext(), Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            return false;
        }
        return true;
    }

    private boolean checkPermissionCamera() {
        if (ContextCompat.checkSelfPermission(cordova.getContext(), Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            return false;
        }
        return true;
    }

    private boolean checkPermissionStorage() {
        if (ContextCompat.checkSelfPermission(cordova.getContext(), Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED) {
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
        if(mainDialog != null) mainDialog.dismiss();
    }

    @Override
    public void onMemberJoin(List<String> userList){
        LOG.e("Tic", "onMemberJoin");
    }

    @Override
    public void onMemberQuit(List<String> userList){
        LOG.e("Tic", "onMemberQuit");
    }

    @Override
    public void onRecordTimestampRequest(ILiveCallBack<Long> callBack){

    }


    @Override
    public void onRecvTextMsg(int type, String s, String s1) {
//        LinkedList<IClassroomIMListener> tmpList = new LinkedList<>(listObservers);
//        for (IClassroomIMListener listener : tmpList) {
//            listener.onRecvTextMsg(type, s, s1);
//        }
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

    @Override
    public void onForceOffline() {

    }

    @Override
    public void onUserSigExpired() {

    }

    private void log(String msg){
        Log.e("TicSdk", msg);
    }
}
