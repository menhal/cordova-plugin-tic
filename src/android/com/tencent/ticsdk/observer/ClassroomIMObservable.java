package com.tencent.ticsdk.observer;

import com.tencent.TIMMessage;
import com.tencent.ticsdk.listener.IClassroomIMListener;

import java.util.LinkedList;

public class ClassroomIMObservable implements IClassroomIMListener {
    // 成员监听链表
    private LinkedList<IClassroomIMListener> listObservers = new LinkedList<IClassroomIMListener>();
    // 句柄
    private static ClassroomIMObservable instance;

    public static ClassroomIMObservable getInstance() {
        if (null == instance) {
            synchronized (ClassroomIMObservable.class) {
                if (null == instance) {
                    instance = new ClassroomIMObservable();
                }
            }
        }
        return instance;
    }

    // 添加观察者
    public void addObserver(IClassroomIMListener listener) {
        if (!listObservers.contains(listener)) {
            listObservers.add(listener);
        }
    }

    // 移除观察者
    public void deleteObserver(IClassroomIMListener listener) {
        listObservers.remove(listener);
    }

    @Override
    public void onRecvTextMsg(int type, String s, String s1) {
        LinkedList<IClassroomIMListener> tmpList = new LinkedList<IClassroomIMListener>(listObservers);
        for (IClassroomIMListener listener : tmpList) {
            listener.onRecvTextMsg(type, s, s1);
        }
    }

    @Override
    public void onRecvCustomMsg(int type, String s, byte[] bytes) {
        LinkedList<IClassroomIMListener> tmpList = new LinkedList<IClassroomIMListener>(listObservers);
        for (IClassroomIMListener listener : tmpList) {
            listener.onRecvCustomMsg(type, s, bytes);
        }
    }

    @Override
    public void onRecvMessage(TIMMessage message) {
        LinkedList<IClassroomIMListener> tmpList = new LinkedList<IClassroomIMListener>(listObservers);
        for (IClassroomIMListener listener : tmpList) {
            listener.onRecvMessage(message);
        }
    }
}
