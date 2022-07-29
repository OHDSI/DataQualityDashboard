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

@Service
@RequiredArgsConstructor
@Slf4j
public class DataQualityProcessServiceImpl implements DataQualityProcessService {
    private final RConnectionCreator rConnectionCreator;
    private final DataQualityResultService resultService;
    private final FilesManagerService filesManagerService;

    @PostConstruct
    public void init() {
        createDirectory(DATA_QUALITY_CHECK_RESULTS_JSON_LOCATION);
    }

    @Async
    @Override
    public Future<Void> runCheckDataQualityProcess(DataQualityScan scan) {
        try {
            String jsonResult;
            try(RConnectionWrapper rConnection = rConnectionCreator.createRConnection()) {
                jsonResult = rConnection.checkDataQuality(scan);
                log.info("Data quality check process successfully finished");
            }
            Path resultJsonFile = Path.of(toResultJsonFilePath(generateRandomFileName()));
            Files.createFile(resultJsonFile);
            try {
                try(BufferedWriter writer = new BufferedWriter(new FileWriter(resultJsonFile.toFile()))) {
                    writer.write(jsonResult);
                }
                FileSaveRequest fileSaveRequest = createFileSaveRequest(resultJsonFile, scan);
                FileSaveResponse fileSaveResponse = filesManagerService.saveFile(fileSaveRequest);
                resultService.saveCompletedResult(fileSaveResponse, scan.getId());
                log.info("Result json file successfully saved");
            } finally {
                Files.delete(resultJsonFile);
            }
        } catch (Exception e) {
            String ABORT_MESSAGE = "Process was aborted by User";
            if (e.getMessage().contains(ABORT_MESSAGE)) {
                log.warn(ABORT_MESSAGE);
            } else {
                log.error("Failed to execute data quality check process: " + e.getMessage());
                e.printStackTrace();
                resultService.saveFailedResult(scan.getId(), e.getMessage());
            }
        }
        return new AsyncResult<>(null);
    }
}
