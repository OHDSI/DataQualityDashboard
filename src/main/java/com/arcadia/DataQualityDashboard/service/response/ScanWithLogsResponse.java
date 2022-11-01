package com.arcadia.DataQualityDashboard.service.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ScanWithLogsResponse {
    private Long id;
    private Integer statusCode;
    private String statusName;
    private List<LogResponse> logs;
}
