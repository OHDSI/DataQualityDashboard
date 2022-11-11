package com.arcadia.DataQualityDashboard.web.controller;

import com.arcadia.DataQualityDashboard.service.r.RConnectionCreator;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR;

@RestController
@RequestMapping("/api/drivers")
@RequiredArgsConstructor
@Slf4j
public class DownloadDriversController {
    private final RConnectionCreator rConnectionCreator;

    @GetMapping()
    public ResponseEntity<Void> getInfo() {
        log.info("Rest request to load JDBC drivers to R server");
        try(RConnectionWrapper rConnection = rConnectionCreator.createRConnection()) {
            rConnection.loadScript(rConnectionCreator.getDownloadJdbcDriversScript());
            return ResponseEntity.noContent().build();
        } catch (Exception e) {
            log.error("Can not load JDBC drivers to Rserve: {}, stack trace: {}", e.getMessage(), e.getStackTrace());
            throw new ResponseStatusException(INTERNAL_SERVER_ERROR, "Can not load JDBC drivers to Rserve: " + e.getMessage(), e);
        }
    }
}
