package com.tencent.ticsdk.cordova;

import android.content.Context;
import android.graphics.Color;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;

public class TicMessageView extends LinearLayout {

    public TicMessageView(Context context, String fromUserId, String text) {
        super(context);
        this.setLayoutParams(this.getContainerLayoutParams());

        TextView userTextView = this.createUserTextView(fromUserId+": ");
        TextView messageTextView = this.createMessageTextView(text);

        this.addView(userTextView);
        this.addView(messageTextView);
    }

    private LayoutParams getContainerLayoutParams(){
        LayoutParams layoutParams = new LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        layoutParams.setLayoutDirection(HORIZONTAL);
        return layoutParams;
    }

    private TextView createUserTextView(String text){
//        ViewGroup.LayoutParams layoutParams = new LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);

        TextView textView = new TextView(this.getContext());
        textView.setText(text);
        textView.setTextColor(Color.BLACK);
//        textView.setLayoutParams(layoutParams);
        return textView;
    }

    private TextView createMessageTextView(String message){
//        ViewGroup.LayoutParams layoutParams = new LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);

        TextView textView = new TextView(this.getContext());
        textView.setText(message);
        textView.setTextColor(Color.GRAY);
//        textView.setLayoutParams(layoutParams);
        return textView;
    }
}
