package com.arcadia.DataQualityDashboard.web.controller;

import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.service.TestConnectionService;
import com.arcadia.DataQualityDashboard.service.response.TestConnectionResultResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import static org.springframework.http.ResponseEntity.ok;

@RestController
@RequestMapping("/api/test-connection")
@RequiredArgsConstructor
@Slf4j
public class TestConnectionController {
    private final TestConnectionService testConnectionService;

    @PostMapping
    public ResponseEntity<TestConnectionResultResponse> testConnection(@Validated @RequestBody DbSettings dbSettings) {
        log.info("Rest request to test connection");
        return ok(testConnectionService.testConnection(dbSettings));
    }
}
