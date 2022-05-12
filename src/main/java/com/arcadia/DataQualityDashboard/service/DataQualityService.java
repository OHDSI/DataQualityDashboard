package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DataQualityResult;
import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.service.response.ScanWithLogsResponse;

public interface DataQualityService {
    DataQualityScan findScanById(Long scanId, String username);

    DataQualityScan createDataQualityScan(DbSettings dbSettings, String username);

    ScanWithLogsResponse scanInfoWithLogs(Long scanId, String username);

    void abort(Long scanId, String username);

    DataQualityResult result(Long scanId, String username);
}
