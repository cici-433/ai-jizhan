package com.aijizhan.ai_jizhan;

import android.content.Context;
import androidx.annotation.NonNull;
import androidx.startup.Initializer;
import androidx.work.Configuration;
import androidx.work.WorkManager;

import java.util.Collections;
import java.util.List;

public class WorkManagerInitializer implements Initializer<WorkManager> {
    @NonNull
    @Override
    public WorkManager create(@NonNull Context context) {
        Configuration configuration = new Configuration.Builder()
                .setDefaultProcessName("com.aijizhan.ai_jizhan")
                .build();
        WorkManager.initialize(context, configuration);
        return WorkManager.getInstance(context);
    }

    @NonNull
    @Override
    public List<Class<? extends Initializer<?>>> dependencies() {
        return Collections.emptyList();
    }
}