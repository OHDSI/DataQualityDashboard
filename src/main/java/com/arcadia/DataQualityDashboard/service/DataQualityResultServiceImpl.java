package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DataQualityLog;
import com.arcadia.DataQualityDashboard.model.DataQualityResult;
import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.model.LogStatus;
import com.arcadia.DataQualityDashboard.repository.DataQualityLogRepository;
import com.arcadia.DataQualityDashboard.repository.DataQualityResultRepository;
import com.arcadia.DataQualityDashboard.repository.DataQualityScanRepository;
import com.arcadia.DataQualityDashboard.service.request.FileSaveRequest;
import com.arcadia.DataQualityDashboard.service.response.FileSaveResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.FileSystemResource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.File;
import java.sql.Timestamp;

import static com.arcadia.DataQualityDashboard.model.LogStatus.ERROR;
import static com.arcadia.DataQualityDashboard.model.LogStatus.INFO;
import static com.arcadia.DataQualityDashboard.model.ScanStatus.COMPLETED;
import static com.arcadia.DataQualityDashboard.model.ScanStatus.FAILED;

@Service
@RequiredArgsConstructor
public class DataQualityResultServiceImpl implements DataQualityResultService {
    public static final String DATA_KEY = "data-quality";

    private final DataQualityScanRepository scanRepository;
    private final DataQualityResultRepository resultRepository;
    private final DataQualityLogRepository logRepository;
    private final FilesManagerService filesManagerService;

    @Transactional
    @Override
    public void saveCompletedResult(File resultJsonFile, Long scanId) {
        DataQualityScan scan = findScanById(scanId);
        FileSystemResource resource = new FileSystemResource(resultJsonFile);
        FileSaveRequest fileSaveRequest = new FileSaveRequest(scan.getUsername(), DATA_KEY, resource);
        FileSaveResponse fileSaveResponse = filesManagerService.saveFile(fileSaveRequest);
        DataQualityLog log = createLastLog("Result json file successfully saved", INFO, scan);
        logRepository.save(log);
        DataQualityResult result = DataQualityResult.builder()
                .fileName(scan.getDbSettings().getDatabase() + ".json")
                .fileKey(fileSaveResponse.getHash())
                .time(new Timestamp(System.currentTimeMillis()))
                .dataQualityScan(scan)
                .build();
        scan.setStatus(COMPLETED);
        scan.setResult(result);
        resultRepository.save(result);
        scanRepository.save(scan);
    }

    @Transactional
    @Override
    public void saveFailedResult(Long scanId, String errorMessage) {
        DataQualityScan scan = findScanById(scanId);
        DataQualityLog log = createLastLog(errorMessage, ERROR, scan);
        logRepository.save(log);
        scan.setStatus(FAILED);
        scanRepository.save(scan);
    }

    private DataQualityScan findScanById(Long scanId) {
        return scanRepository.findById(scanId)
                .orElseThrow(() -> new RuntimeException("Data Quality Scan not found by id " + scanId));
    }

    private DataQualityLog createLastLog(String message, LogStatus status, DataQualityScan scan) {
        return DataQualityLog.builder()
                .message(message)
                .statusCode(status.getCode())
                .statusName(status.getName())
                .time(new Timestamp(System.currentTimeMillis()))
                .percent(100)
                .dataQualityScan(scan)
                .build();
    }
}
