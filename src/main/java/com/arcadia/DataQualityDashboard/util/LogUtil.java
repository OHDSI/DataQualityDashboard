package com.arcadia.DataQualityDashboard.util;

import com.arcadia.DataQualityDashboard.model.DataQualityLog;
import com.arcadia.DataQualityDashboard.service.response.LogResponse;

public class LogUtil {
    public static LogResponse toLogResponse(DataQualityLog log) {
        return LogResponse.builder()
                .message(log.getMessage())
                .percent(log.getPercent())
                .statusCode(log.getStatusCode())
                .statusName(log.getStatusName())
                .build();
    }
}
