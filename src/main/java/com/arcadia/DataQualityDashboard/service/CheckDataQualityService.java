package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.dto.DbSettings;
import com.arcadia.DataQualityDashboard.dto.ProgressNotificationStatus;
import lombok.AllArgsConstructor;
import lombok.SneakyThrows;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.AsyncResult;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Future;

import static com.arcadia.DataQualityDashboard.util.OperationSystem.isUnix;
import static java.lang.String.format;

@Service
@AllArgsConstructor
public class CheckDataQualityService {

    private final StorageService storageService;

    private final WebSocketHandler webSocketHandler;

    private final RConnectionCreator rConnectionCreator;

    private final ConcurrentHashMap<String, Integer> processes = new ConcurrentHashMap<>();

    @SneakyThrows
    @PostConstruct
    public void init() {
        if (isUnix()) {
            RConnectionWrapper rConnection = rConnectionCreator.createRConnection();
            rConnection.loadScripts();
            rConnection.close();
        }
    }

    @SneakyThrows
    @Async
    public Future<String> checkDataQuality(DbSettings dbSettings, String userId) {
        RConnectionWrapper rConnection = rConnectionCreator.createRConnection();

        Integer pid = rConnection.getRServerPid();
        processes.put(userId, pid);

        try {
            String jsonResult = rConnection.checkDataQuality(dbSettings, userId);
            rConnection.close();
            String result = storageService.store(format("%s.json", userId), jsonResult);
            webSocketHandler.sendMessageToUser("Result json generated", userId, ProgressNotificationStatus.FINISHED);

            return new AsyncResult<>(result);
        } catch (RException e) {
            webSocketHandler.sendMessageToUser(e.getMessage(), userId, ProgressNotificationStatus.FAILED);
            throw e;
        }
    }

    @SneakyThrows
    public void cancelCheckDataQualityProcess(String userId) {
        Integer pid = processes.get(userId);

        if (pid != null) {
            RConnectionWrapper rConnection = rConnectionCreator.createRConnection();
            rConnection.cancel(pid);
            rConnection.close();
        }
    }
}
