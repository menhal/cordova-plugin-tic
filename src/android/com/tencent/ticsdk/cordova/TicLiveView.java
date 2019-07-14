package com.tencent.ticsdk.cordova;

import com.tencent.ilivesdk.view.ILiveRootView;

import android.content.Context;
import android.graphics.Color;
import android.text.Layout;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.TextView;

public class TicLiveView extends FrameLayout{

    private int score = 0;
    private ILiveRootView renderView = null;
    private TextView startView = null;
    public String userId = "";
    private Context context = null;

    TicLiveView(Context context){
        super(context);


        this.context = context;
//        this.setBackgroundColor(Color.RED);

        initViews();


        this.post(new Runnable(){
            public void run(){
                addLayoutParams();
                addStarLayoutParms();
                setScore(score);
            }
        });
    }


    void initViews(){
        renderView = new ILiveRootView(context);
        renderView.initViews();
        renderView.setDeviceRotation(180);

        startView = new TextView(context);
        startView.setTextColor(Color.parseColor("#ffd630"));


        addView(renderView);
        addView(startView);
    }

    void render(String userId){
        this.userId = userId;
        renderView.render(userId, 1);
    }


    void addLayoutParams(){
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        renderView.setLayoutParams(lp);
    }

    void addStarLayoutParms(){
        FrameLayout.LayoutParams lp = new FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT, Gravity.END);
        lp.rightMargin = 10;
        startView.setLayoutParams(lp);
    }

    void setScore(int score){
        this.score = score;
        startView.setText("★"+score);
    }

    void closeVideo(){
        renderView.closeVideo();
    }

}
