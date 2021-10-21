package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.dto.DbSettings;
import lombok.AllArgsConstructor;
import lombok.SneakyThrows;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.AsyncResult;
import org.springframework.stereotype.Service;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Future;

import static com.arcadia.DataQualityDashboard.dto.ProgressNotificationStatus.FAILED;
import static com.arcadia.DataQualityDashboard.dto.ProgressNotificationStatus.FINISHED;
import static java.lang.String.format;

@Service
@AllArgsConstructor
public class CheckDataQualityService {

    private final StorageService storageService;

    private final WebSocketHandler webSocketHandler;

    private final RConnectionCreator rConnectionCreator;

    private final ConcurrentHashMap<String, Integer> processes = new ConcurrentHashMap<>();

    @Async
    public Future<String> checkDataQuality(DbSettings dbSettings, String userId) throws RException, DbTypeNotSupportedException {
        try {
            RConnectionWrapper rConnection = rConnectionCreator.createRConnection();

            Integer pid = rConnection.getRServerPid();
            processes.put(userId, pid);

            String jsonResult = rConnection.checkDataQuality(dbSettings, userId);
            rConnection.close();
            String result = storageService.store(format("%s.json", userId), jsonResult);
            webSocketHandler.sendMessageToUser("Result json generated", userId, FINISHED);

            return new AsyncResult<>(result);
        } catch (RException | DbTypeNotSupportedException e) {
            webSocketHandler.sendMessageToUser(e.getMessage(), userId, FAILED);
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
