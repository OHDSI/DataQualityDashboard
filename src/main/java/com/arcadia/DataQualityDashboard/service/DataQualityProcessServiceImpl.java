package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.service.r.RConnectionCreator;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.AsyncResult;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.util.concurrent.Future;

import static com.arcadia.DataQualityDashboard.util.FileUtil.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class DataQualityProcessServiceImpl implements DataQualityProcessService {
    private final RConnectionCreator rConnectionCreator;
    private final DataQualityResultService resultService;

    @PostConstruct
    public void init() {
        createDirectory(DATA_QUALITY_CHECK_RESULTS_JSON_LOCATION);
    }

    @Async
    @Override
    public Future<Void> runCheckDataQualityProcess(DataQualityScan scan) {
        try {
            RConnectionWrapper rConnection = rConnectionCreator.createRConnection();
            String jsonResult = rConnection.checkDataQuality(scan);
            rConnection.close();
            log.info("Data quality check process successfully finished");

            String resultJsonFilePath = toResultJsonFilePath(generateRandomFileName());
            File resultJsonFile = new File(resultJsonFilePath);
            try {
                BufferedWriter writer = new BufferedWriter(new FileWriter(resultJsonFilePath, false));
                writer.write(jsonResult);
                writer.close();
                resultService.saveCompletedResult(resultJsonFile, scan.getId());
                log.info("Result json file successfully saved");
            } finally {
                resultJsonFile.delete();
            }
        } catch (Exception e) {
            String errorMessage = e.getMessage();
            String abortMessage = "Process was aborted by User";
            if (errorMessage.contains(abortMessage)) {
                log.warn(abortMessage);
            } else {
                log.error("Failed to run data quality check process: " + errorMessage);
                resultService.saveFailedResult(scan.getId(), errorMessage);
            }
        }

        return new AsyncResult<>(null);
    }
}
