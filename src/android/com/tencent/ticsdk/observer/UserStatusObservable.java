package com.tencent.ticsdk.observer;

import com.tencent.TIMUserStatusListener;

import java.util.LinkedList;

public class UserStatusObservable implements TIMUserStatusListener {
    // 成员监听链表
    private LinkedList<TIMUserStatusListener> listObservers = new LinkedList<TIMUserStatusListener>();
    // 句柄
    private static UserStatusObservable instance;

    public static UserStatusObservable getInstance() {
        if (null == instance) {
            synchronized (UserStatusObservable.class) {
                if (null == instance) {
                    instance = new UserStatusObservable();
                }
            }
        }
        return instance;
    }

    // 添加观察者
    public void addObserver(TIMUserStatusListener listener) {
        if (!listObservers.contains(listener)) {
            listObservers.add(listener);
        }
    }

    // 移除观察者
    public void deleteObserver(TIMUserStatusListener listener) {
        listObservers.remove(listener);
    }

    @Override
    public void onForceOffline() {
        LinkedList<TIMUserStatusListener> tmpList = new LinkedList<TIMUserStatusListener>(listObservers);
        for (TIMUserStatusListener listener : tmpList) {
            listener.onForceOffline();
        }
    }

    @Override
    public void onUserSigExpired() {
        LinkedList<TIMUserStatusListener> tmpList = new LinkedList<TIMUserStatusListener>(listObservers);
        for (TIMUserStatusListener listener : tmpList) {
            listener.onUserSigExpired();
        }
    }
}
