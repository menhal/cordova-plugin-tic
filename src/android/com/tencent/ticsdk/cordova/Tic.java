package com.tencent.ticsdk.cordova;

import android.Manifest;
import android.app.Activity;
import android.app.Dialog;
import android.content.DialogInterface;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.media.Image;
import android.os.Build;
import android.os.Handler;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import com.tencent.TIMUserStatusListener;
import com.tencent.boardsdk.board.WhiteboardView;
import com.tencent.ilivesdk.ILiveCallBack;
import com.tencent.ilivesdk.ILiveSDK;
import com.tencent.ilivesdk.adapter.CommonConstants;
import com.tencent.ilivesdk.adapter.ContextEngine;
import com.tencent.ilivesdk.view.ILiveRootView;
import com.tencent.ticsdk.TICClassroomOption;
import com.tencent.ticsdk.TICManager;
import com.tencent.ticsdk.TICSDK;
import com.tencent.ticsdk.listener.IClassEventListener;
import com.tencent.ticsdk.observer.ClassEventObservable;
import com.tencent.ticsdk.observer.ClassroomIMObservable;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.LOG;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.w3c.dom.Text;

import java.util.ArrayList;
import java.util.Dictionary;
import java.util.List;



public class Tic extends CordovaPlugin implements IClassEventListener, TicMessageListener, TIMUserStatusListener {

    //    CallbackContext callbackContext;
    final static int REQUEST_CODE = 1;

    private String showTeacherName = "管理员";

    private boolean isRunning = false;
    private boolean isShowStudents = true;  // 是否折叠学生视图

    private Dialog mainDialog = null;
    private Button handBtn = null;  // 举手按钮
    private Button collapseBtn = null; // 折叠按钮
    private View toggleBtn = null; // 交换按钮
    private ViewGroup layoutLeftBottom = null; // 学生列表Layout
    private ViewGroup layoutRightBottom = null; // 右侧聊天窗
    private View closeBtn = null; // 退出按钮
    private ViewGroup layoutLeftTopWrapper = null; // 组视频/白板区域的container
    private View leftBtn = null;  // 左滑按钮
    private View rightBtn = null; // 右滑按钮
    private HorizontalScrollView av_root_scroll = null; // 学生列表横向滚动视图
    private ViewGroup av_root_container = null;  // 学生列表container
    private ILiveRootView av_teacher_view = null; // 教师视频
    private TicLiveView av_self_view = null; // 教师视频
    private WhiteboardView whiteboardview = null;  // 白板视图
    private LinearLayout MessageContainer = null; // 聊天内容
    private ScrollView chatScrollView = null; // 聊天滚动区
    private EditText editText = null; // 输入框
    private ViewGroup av_self_view_container = null;
    private TextView titleView = null; // 页面标题
    private ImageView animate = null; // 动画

    private int roomId = 0;
    private String teacherId = "";
    private String userId = "";
    private String userSig = "";
    private String truename = "";
    private String role = "";
    private CallbackContext callbackContext = null;
    private TicMessageHandler messageHandler = null;
    private JSONObject userScores = new JSONObject();
    private String roomName = "";

    @Override
    protected void pluginInitialize() {
        messageHandler = new TicMessageHandler();
        messageHandler.setMessageListener(this);

//        TICSDK.getInstance().initSDK(cordova.getActivity(), sdkappid);
//        checkCameraAndMicPermission();
    }


    @Override
    public boolean execute(String action, CordovaArgs args, CallbackContext callbackContext) throws JSONException {

        this.callbackContext = callbackContext;

//        initLayout();
//        return true;

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


    private void initScores(JSONArray scoreList){

        for(int i=0; i<scoreList.length(); i++){

            try{
                JSONObject data = scoreList.getJSONObject(i);
                String userId = data.optString("userId");
                int integral = data.optInt("integral");

                userScores.put(userId, integral);
            } catch (JSONException e){
                log(e.getMessage());
            }

        }

    }


    private void join(JSONObject options){
        if(isRunning) return;

        userId = options.optString("userName");
        userSig = options.optString("userSig");
        roomId = options.optInt("roomId");
        role = options.optString("role");
        teacherId = options.optString("teacherId");
        truename = options.optString("truename");
        roomName = options.optString("roomName");
        initScores(options.optJSONArray("userScores"));

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
        ClassroomIMObservable.getInstance().deleteObserver(messageHandler);

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


    // 初始化控件和布局
    private void initLayout(){
        cordova.getActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);

        Activity activity = cordova.getActivity();

        // 添加主对话框
        mainDialog = new Dialog(activity, android.R.style.Theme_Black_NoTitleBar_Fullscreen);
        mainDialog.setContentView(getIdentifier("tic_main", "layout"));


        handBtn = (Button) findViewById("handBtn");  // 举手按钮
        collapseBtn = (Button) findViewById("collapseBtn"); // 折叠按钮
        toggleBtn = findViewById("toggleBtn"); // 交换按钮
        layoutLeftBottom = (ViewGroup) findViewById("LayoutLeftBottom"); // 学生列表Layout
        layoutRightBottom = (ViewGroup) findViewById("LayoutRightBottom"); // 右侧聊天窗
        closeBtn = findViewById("closeBtn"); // 退出按钮
        layoutLeftTopWrapper = (ViewGroup) findViewById("LayoutLeftTopWrapper"); // 组视频/白板区域的container
        leftBtn = findViewById("leftBtn");  // 左滑按钮
        rightBtn = findViewById("rightBtn"); // 右滑按钮
        av_root_scroll = (HorizontalScrollView) findViewById("av_root_scroll"); // 学生列表横向滚动视图
        av_root_container = (ViewGroup) findViewById("av_root_container");  // 学生列表container
        av_teacher_view = (ILiveRootView) findViewById("av_teacher_view"); // 教师视频
//        av_self_view = (TicLiveView) findViewById("av_self_view"); // 本人视频
        whiteboardview = (WhiteboardView) findViewById("whiteboardview");  // 白板视图
        MessageContainer = (LinearLayout) findViewById("MessageContainer");
        chatScrollView = (ScrollView) findViewById("ChatScrollView"); // 聊天滚动区
        editText = (EditText) findViewById("editText"); // 输入框
        animate = (ImageView) findViewById("animate"); // 动画
        av_self_view_container =  (ViewGroup) findViewById("av_self_view_container"); // 本人视频
        titleView = (TextView) findViewById("title"); //
        av_self_view = new TicLiveView(activity);
        av_self_view.initViews();
        av_self_view_container.addView(av_self_view);

        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        av_self_view.setLayoutParams(lp);


        titleView.setText(roomName);

        // 关闭对话框事件
        mainDialog.setOnCancelListener(new DialogInterface.OnCancelListener() {
            @Override
            public void onCancel(DialogInterface dialog) {
                logout();
            }
        });

        // 收起按钮
        collapseBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                isShowStudents = !isShowStudents;
                resetLayout();
            }
        });

        // 交换按钮
        toggleBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                toggleScreen();
            }
        });

        // 关闭按钮点击
        closeBtn.setOnClickListener(new View.OnClickListener(){
            @Override
            public void onClick(View v){
                mainDialog.cancel();
            }
        });

        // 添加左划按钮
        leftBtn.setOnClickListener(new View.OnClickListener(){
            @Override
            public void onClick(View v){
                av_root_scroll.arrowScroll(View.FOCUS_LEFT);
            }
        });

        // 添加右划按钮
        rightBtn.setOnClickListener(new View.OnClickListener(){
            @Override
            public void onClick(View v){
                av_root_scroll.arrowScroll(View.FOCUS_RIGHT);
            }
        });

        // 添加举手按钮
        handBtn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                onHandButtonClick();
            }
        });

        // 聊天输入
        editText.setOnEditorActionListener(new TextView.OnEditorActionListener(){

            @Override
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                if (actionId == EditorInfo.IME_ACTION_SEARCH ||
                        actionId == EditorInfo.IME_ACTION_DONE ||
                        event != null &&
                                event.getAction() == KeyEvent.ACTION_DOWN &&
                                event.getKeyCode() == KeyEvent.KEYCODE_ENTER) {
                    if (event == null || !event.isShiftPressed()) {
                        // the user is done typing.
                        String message = editText.getText().toString();
                        messageHandler.sendBroadcast(message, userId, truename);
                        showMessage(truename, message);
                        editText.setText("");
                        return false; // consume.
                    }
                }
                return false;
            }
        });

        mainDialog.show();
    }


    // 切换布局
    private void resetLayout(){

        if(isShowStudents){

            layoutLeftBottom.setVisibility(View.VISIBLE);
            layoutRightBottom.setVisibility(View.VISIBLE);
            av_self_view_container.setVisibility(View.GONE);
            collapseBtn.setText("收起");
            stopSelfVideo();
            createMemberVideos();

        } else {

            layoutLeftBottom.setVisibility(View.GONE);
            layoutRightBottom.setVisibility(View.GONE);
            av_self_view_container.setVisibility(View.VISIBLE);
            collapseBtn.setText("展开");
            clearMemberVideos();
            renderSelfVideo();
        }
    }


    // 切换白板和视频
    private void toggleScreen(){

        ViewGroup postion1 = (ViewGroup) av_teacher_view.getParent();
        ViewGroup postion2 = (ViewGroup) whiteboardview.getParent();

        postion1.removeView(av_teacher_view);
        postion2.removeView(whiteboardview);

        postion1.addView(whiteboardview, 0);
        postion2.addView(av_teacher_view, 0);

//        if(isShowStudents){
//            clearMemberVideos();
//            createMemberVideos();
//        }
    }

    private void onJoinRoomSuccess(){
        cordova.getActivity().setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE);
        sendPluginResult();


        ClassEventObservable.getInstance().addObserver(this);
        ClassroomIMObservable.getInstance().addObserver(messageHandler);
        messageHandler.setTeacherId(teacherId);

        initLayout();

        // 教师屏幕和各学员屏幕
        av_teacher_view.initViews();
        av_teacher_view.render(teacherId, 1);

        // 禁止学员操作白板
        whiteboardview.setWhiteboardEnable(false);

        // 各学员视图
//        createMemberVideos();
        resetLayout();

        log("加入房间成功");
    }

    private void onJoinRoomFailed(int errCode, String errMsg){
        sendErrorMessage(errCode, errMsg);
    }


    private void createMemberVideos(){
        ContextEngine contextEngine = ILiveSDK.getInstance().getContextEngine();
        List<String> userList = contextEngine.getVideoUserList(CommonConstants.Const_VideoType_Camera);

        renderUserVideo(userId);

        for (String currentId : userList) {
            if(currentId.equals(teacherId)) continue;
            if(currentId.equals(userId)) continue;
            renderUserVideo(currentId);
        }
    }

    private void clearMemberVideos(){
        LinearLayout layout = (LinearLayout) findViewById("av_root_container");

        for (int i = 0; i < layout.getChildCount(); i++) {
            TicLiveView video = (TicLiveView) layout.getChildAt(i);
            video.closeVideo();

            layout.post(new Runnable(){
                public void run(){
                    layout.removeView(video);
                }
            });
        }
    }


    private void renderSelfVideo(){
        int score = userScores.optInt(userId, 0);

        av_self_view.render(userId);
        av_self_view.setScore(score);
    }

    private void stopSelfVideo(){
        av_self_view.closeVideo();
    }


    private void renderUserVideo(String userId){
        final LinearLayout layout = (LinearLayout) findViewById("av_root_container");

        final TicLiveView liveView = new TicLiveView(mainDialog.getContext());
        liveView.initViews();
        liveView.render(userId);
        layout.addView(liveView);
        updateUserScore(userId);

        layout.post(new Runnable(){
            public void run(){
                int height = layout.getHeight();
                LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(height, height);
                lp.rightMargin = 20;
                liveView.setLayoutParams(lp);
            }
        });
    }

    private void removeUserVideo(String userId){
        LinearLayout layout = (LinearLayout) findViewById("av_root_container");

        for (int i = 0; i < layout.getChildCount(); i++) {
            TicLiveView video = (TicLiveView) layout.getChildAt(i);

            if(video.userId.equals(userId)) {
                video.closeVideo();

                layout.post(new Runnable(){
                    public void run(){
                        layout.removeView(video);
                    }
                });
            }
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
            showMessage("群消息提示", newUserId+"进入房间");
        }
    }

    @Override
    public void onMemberQuit(List<String> userList){
        LOG.e("Tic", "onMemberQuit");

        for (String quitUserId : userList) {
            if(quitUserId.equals(teacherId)) continue;
            if(quitUserId.equals(userId)) continue;
            removeUserVideo(quitUserId);
            showMessage("群消息提示", quitUserId+"退出了房间");
        }
    }

    @Override
    public void onRecordTimestampRequest(ILiveCallBack<Long> callBack){

    }

    // 接收到远程指令
    @Override
    public void onCommand(String text) {
        if(text.equals("TIMCustomHandReplyYes")){
            messageHandler.sendCommand("TIMCustomHandRecOpenOk");
            setMic(true);
            handBtn.setText("正在发言");
            showMessage(showTeacherName, "你正在发言");
        } else if(text.equals("TIMCustomHandReplyNo")){
            messageHandler.sendCommand("TIMCustomHandRecCloseOk");
            setMic(false);
            handBtn.setText("我要发言");
            showMessage(showTeacherName, "你已结束发言");
        }
    }

    // 接收到群聊消息
    @Override
    public void onBroadcast(String fromUserId, String text) {
        showMessage(fromUserId, text);
    }

    @Override
    public void onScore(String userId, int integral, int addIntegral, String msg) {

        try{
            userScores.put(userId, integral);
//            animate.setVisibility(View.VISIBLE);

        } catch (JSONException e){

            log(e.getMessage());
        }

        updateUserScore(userId);
    }


    private void updateUserScore(String userId){

        LinearLayout layout = (LinearLayout) findViewById("av_root_container");
        int score = userScores.optInt(userId, 0);

        for (int i = 0; i < layout.getChildCount(); i++) {
            TicLiveView video = (TicLiveView) layout.getChildAt(i);

            if(video.userId.equals(userId)) {
                video.setScore(score);
                if(userId.equals(this.userId)) av_self_view.setScore(score);
            }
        }
    }

    // 在对话框显示聊天信息
    private void showMessage(String fromUserId, String text){
        String fromUserText = fromUserId.equals(teacherId) ? showTeacherName : fromUserId;
        TicMessageView messageView = new TicMessageView(cordova.getContext(), fromUserText, text);
        MessageContainer.addView(messageView);

        MessageContainer.post(new Runnable() {
            @Override
            public void run() {
                chatScrollView.scrollTo(0, 999999);
            }
        });
    }

    // 学生举手
    private void onHandButtonClick(){
        if(!"我要发言".equals(handBtn.getText())) return;

        handBtn.setText("等待老师同意...");
        messageHandler.sendCommand("TIMCustomHand");
    }

    @Override
    public void onForceOffline() {
        LOG.e("Tic", "onForceOffline");
        if(mainDialog != null) mainDialog.cancel();
    }

    @Override
    public void onUserSigExpired() {
        LOG.e("Tic", "onUserSigExpired");
        if(mainDialog != null) mainDialog.cancel();
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
