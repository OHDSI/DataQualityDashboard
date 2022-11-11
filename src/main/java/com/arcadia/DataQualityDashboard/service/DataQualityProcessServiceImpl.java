package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.service.r.RConnectionCreator;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import com.arcadia.DataQualityDashboard.service.request.FileSaveRequest;
import com.arcadia.DataQualityDashboard.service.response.FileSaveResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.AsyncResult;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.concurrent.Future;

import static com.arcadia.DataQualityDashboard.util.FileSaveRequestUtil.createFileSaveRequest;
import static com.arcadia.DataQualityDashboard.util.FileUtil.*;
import static java.nio.charset.StandardCharsets.UTF_8;

@Service
@RequiredArgsConstructor
@Slf4j
public class DataQualityProcessServiceImpl implements DataQualityProcessService {
    private final RConnectionCreator rConnectionCreator;
    private final DataQualityResultService resultService;
    private final FilesManagerService filesManagerService;

    @PostConstruct
    public void init() {
        createDirectory(RESULTS_JSON_LOCATION);
    }

    @Async
    @Override
    public Future<Void> runCheckDataQualityProcess(DataQualityScan scan) {
        try {
            String jsonResult;
            try(RConnectionWrapper rConnection = rConnectionCreator.createRConnection()) {
                jsonResult = rConnection.checkDataQuality(scan);
                log.info("Data quality check process successfully finished. Scan id: {}, username: {}.",
                        scan.getId(),
                        scan.getUsername()
                );
            }
            Path resultJsonPath = Path.of(RESULTS_JSON_LOCATION, generateRandomFileName());
            Files.createFile(resultJsonPath);
            try {
                try(BufferedWriter writer = new BufferedWriter(new FileWriter(resultJsonPath.toFile(), UTF_8))) {
                    writer.write(jsonResult);
                }
                FileSaveRequest fileSaveRequest = createFileSaveRequest(resultJsonPath, scan);
                FileSaveResponse fileSaveResponse = filesManagerService.saveFile(fileSaveRequest);
                log.info("Result json file successfully saved. Scan id: {}, username: {}.",
                        scan.getId(),
                        scan.getUsername()
                );
                resultService.saveCompletedResult(fileSaveResponse, scan.getId());
            } finally {
                Files.delete(resultJsonPath);
            }
        } catch (Exception e) {
            if (e.getMessage().contains("Process was aborted by User")) {
                log.info("Scan process with id {} was aborted by user {}",
                        scan.getId(),
                        scan.getUsername()
                );
            } else {
                log.error("Data quality check process failed, id: {}, username: {}, error message: {}. Stack trace: {}",
                        scan.getId(),
                        scan.getUsername(),
                        e.getMessage(),
                        e.getStackTrace()
                );
                resultService.saveFailedResult(scan.getId(), e.getMessage());
            }
        }
        return new AsyncResult<>(null);
    }
}
