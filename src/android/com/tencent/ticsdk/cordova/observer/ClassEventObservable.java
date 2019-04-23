package com.tencent.ticsdk.observer;

import com.tencent.ilivesdk.ILiveCallBack;
import com.tencent.ticsdk.listener.IClassEventListener;

import java.util.LinkedList;
import java.util.List;

public class ClassEventObservable implements IClassEventListener {

    // 成员监听链表
    private LinkedList<IClassEventListener> listObservers = new LinkedList<>();
    // 句柄
    private static ClassEventObservable instance;

    public static ClassEventObservable getInstance() {
        if (null == instance) {
            synchronized (ClassEventObservable.class) {
                if (null == instance) {
                    instance = new ClassEventObservable();
                }
            }
        }
        return instance;
    }

    // 添加观察者
    public void addObserver(IClassEventListener listener) {
        if (!listObservers.contains(listener)) {
            listObservers.add(listener);
        }
    }

    // 移除观察者
    public void deleteObserver(IClassEventListener listener) {
        listObservers.remove(listener);
    }

    @Override
    public void onLiveVideoDisconnect(int i, String s) {
        LinkedList<IClassEventListener> tmpList = new LinkedList<>(listObservers);
        for (IClassEventListener listener : tmpList) {
            listener.onLiveVideoDisconnect(i, s);
        }
    }

    @Override
    public void onClassroomDestroy() {
        LinkedList<IClassEventListener> tmpList = new LinkedList<>(listObservers);
        for (IClassEventListener listener : tmpList) {
            listener.onClassroomDestroy();
        }
    }

    @Override
    public void onMemberJoin(List<String> list) {
        LinkedList<IClassEventListener> tmpList = new LinkedList<>(listObservers);
        for (IClassEventListener listener : tmpList) {
            listener.onMemberJoin(list);
        }
    }

    @Override
    public void onMemberQuit(List<String> list) {
        LinkedList<IClassEventListener> tmpList = new LinkedList<>(listObservers);
        for (IClassEventListener listener : tmpList) {
            listener.onMemberQuit(list);
        }
    }

    @Override
    public void onRecordTimestampRequest(ILiveCallBack<Long> callBack) {
        LinkedList<IClassEventListener> tmpList = new LinkedList<>(listObservers);
        for (IClassEventListener listener : tmpList) {
            listener.onRecordTimestampRequest(callBack);
        }
    }
}
