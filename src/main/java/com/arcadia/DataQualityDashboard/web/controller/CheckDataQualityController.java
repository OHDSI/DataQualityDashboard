package com.arcadia.DataQualityDashboard.web.controller;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.service.DataQualityProcessService;
import com.arcadia.DataQualityDashboard.service.DataQualityService;
import com.arcadia.DataQualityDashboard.service.response.ScanWithLogsResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import static org.springframework.http.ResponseEntity.noContent;
import static org.springframework.http.ResponseEntity.ok;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
@Slf4j
public class CheckDataQualityController {
    private final DataQualityService dataQualityService;
    private final DataQualityProcessService processService;

    @PostMapping("/scan")
    public ResponseEntity<DataQualityScan> runScanProcess(@RequestHeader("Username") String username,
                                                          @Validated @RequestBody DbSettings dbSettings) {
        log.info("Rest request to run Data Quality Check process");
        DataQualityScan scan = dataQualityService.createDataQualityScan(dbSettings, username);
        processService.runCheckDataQualityProcess(scan);
        return ok(scan);
    }

    @GetMapping("/abort/{scanId}")
    public ResponseEntity<Void> abort(@RequestHeader("Username") String username,
                                      @PathVariable Long scanId) {
        log.info("Rest request to abort Data Quality Check process by id {}", scanId);
        dataQualityService.abort(scanId, username);
        return noContent().build();
    }

    @GetMapping("/scan/{scanId}")
    public ResponseEntity<ScanWithLogsResponse> scanInfoWithLogs(@RequestHeader("Username") String username,
                                                                 @PathVariable Long scanId) {
        log.info("Rest request to get Data Quality Check process info with logs by id {}", scanId);
        return ok(dataQualityService.scanInfoWithLogs(scanId, username));
    }
}
