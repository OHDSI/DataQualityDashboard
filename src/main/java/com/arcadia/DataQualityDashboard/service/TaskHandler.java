package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.dto.DbSettings;
import lombok.AllArgsConstructor;
import lombok.SneakyThrows;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Future;

@Service
@AllArgsConstructor
public class TaskHandler {

    private final CheckDataQualityService checkDataQualityService;

    private final Map<String, Future<String>> tasks = new ConcurrentHashMap<>();

    @SneakyThrows
    public boolean createTask(DbSettings dbSettings, String userId) {
        if (tasks.containsKey(userId)) {
            return false;
        }
        Future<String> newTask = checkDataQualityService.checkDataQuality(dbSettings, userId);

        tasks.put(userId, newTask);

        return true;
    }

    @SneakyThrows
    public String getTaskResult(String userId) {
        Future<String> task = this.tasks.get(userId);
        tasks.remove(userId);

        return task.get();
    }

    public void cancelTask(String userId) {
        checkDataQualityService.cancelCheckDataQualityProcess(userId);

        Future<String> task = tasks.remove(userId);
        if (task != null) {
            task.cancel(true);
        }
    }
}

