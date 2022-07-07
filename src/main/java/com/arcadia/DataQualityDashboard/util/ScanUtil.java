package com.arcadia.DataQualityDashboard.util;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.service.response.ScanWithLogsResponse;

import java.util.stream.Collectors;

public class ScanUtil {
    public static ScanWithLogsResponse toScanWithLogsResponse(DataQualityScan scan) {
        return ScanWithLogsResponse.builder()
                .id(scan.getId())
                .statusCode(scan.getStatusCode())
                .statusName(scan.getStatusName())
                .logs(scan.getLogs().stream().map(LogUtil::toLogResponse).collect(Collectors.toList()))
                .build();
    }
}
