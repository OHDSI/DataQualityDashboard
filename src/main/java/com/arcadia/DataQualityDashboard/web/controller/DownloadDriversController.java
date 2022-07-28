package com.arcadia.DataQualityDashboard.web.controller;

import com.arcadia.DataQualityDashboard.service.r.RConnectionCreator;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/drivers")
@RequiredArgsConstructor
@Slf4j
public class DownloadDriversController {
    private final RConnectionCreator rConnectionCreator;

    @GetMapping()
    public ResponseEntity<Void> getInfo() {
        log.info("Rest request to get App info");
        RConnectionWrapper rConnection = rConnectionCreator.createRConnection();
        rConnection.loadScript(rConnectionCreator.getDownloadJdbcDriversScript());
        return ResponseEntity.noContent().build();
    }
}
