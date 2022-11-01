package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DataQualityLog;
import com.arcadia.DataQualityDashboard.model.DataQualityResult;
import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.repository.DataQualityLogRepository;
import com.arcadia.DataQualityDashboard.repository.DataQualityResultRepository;
import com.arcadia.DataQualityDashboard.repository.DataQualityScanRepository;
import com.arcadia.DataQualityDashboard.service.response.ScanWithLogsResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

import static com.arcadia.DataQualityDashboard.model.ScanStatus.ABORTED;
import static com.arcadia.DataQualityDashboard.model.ScanStatus.IN_PROGRESS;
import static com.arcadia.DataQualityDashboard.util.ScanUtil.toScanWithLogsResponse;
import static org.springframework.http.HttpStatus.FORBIDDEN;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
@RequiredArgsConstructor
public class DataQualityServiceImpl implements DataQualityService {
    private final DataQualityScanRepository scanRepository;
    private final DataQualityLogRepository logRepository;
    private final DataQualityResultRepository resultRepository;

    @Override
    public DataQualityScan findScanById(Long scanId, String username) {
        DataQualityScan scan = scanRepository.findById(scanId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Data Quality Scan not found by id " + scanId));
        if (!scan.getUsername().equals(username)) {
            throw new ResponseStatusException(FORBIDDEN, "Forbidden to get Data Quality Scan for other user");
        }
        return scan;
    }

    @Transactional
    @Override
    public DataQualityScan createDataQualityScan(DbSettings dbSettings, String username) {
        String project = dbSettings.getDatabase();
        DataQualityScan scan = DataQualityScan.builder()
                .username(username)
                .project(project)
                .statusCode(IN_PROGRESS.getCode())
                .statusName(IN_PROGRESS.getName())
                .dbSettings(dbSettings)
                .build();
        dbSettings.setDataQualityScan(scan);
        scanRepository.saveAndFlush(scan);

        return scan;
    }

    @Override
    public ScanWithLogsResponse scanInfoWithLogs(Long scanId, String username) {
        DataQualityScan scan = findScanById(scanId, username);
        List<DataQualityLog> logs = logRepository.findAllByDataQualityScanId(scan.getId())
                .stream()
                .sorted(Comparator.comparing(DataQualityLog::getId))
                .collect(Collectors.toList());
        scan.setLogs(logs);

        return toScanWithLogsResponse(scan);
    }

    @Transactional
    @Override
    public void abort(Long scanId, String username) {
        DataQualityScan scan = findScanById(scanId, username);
        scan.setStatus(ABORTED);
        scanRepository.save(scan);
    }

    @Override
    public DataQualityResult result(Long scanId, String username) {
        DataQualityScan scan = findScanById(scanId, username);
        return resultRepository.findByDataQualityScanId(scan.getId())
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Data Quality Scan Result not found by scan id " + scanId));
    }
}
