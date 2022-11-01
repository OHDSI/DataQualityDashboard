package com.arcadia.DataQualityDashboard.web.controller;

import com.arcadia.DataQualityDashboard.model.DataQualityResult;
import com.arcadia.DataQualityDashboard.service.DataQualityService;
import com.arcadia.DataQualityDashboard.service.FilesManagerService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import static java.lang.String.format;
import static org.springframework.http.HttpHeaders.CONTENT_DISPOSITION;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.http.ResponseEntity.ok;

@RestController
@RequestMapping("/json")
@RequiredArgsConstructor
@Slf4j
public class JsonResultController {
    private final DataQualityService dataQualityService;
    private final FilesManagerService filesManagerService;

    @GetMapping("/{scanId}")
    public ResponseEntity<Resource> downloadResultJsonFile(@RequestHeader("Username") String username,
                                                           @PathVariable Long scanId) {
        log.info("Rest request to download Data Quality Check result json file by id {}", scanId);
        DataQualityResult result = dataQualityService.result(scanId, username);
        Resource resource = filesManagerService.getFile(result.getFileId());
        return ok()
                .contentType(APPLICATION_JSON)
                .header(CONTENT_DISPOSITION, format("attachment; filename=\"%S\"", result.getFileName()))
                .body(resource);
    }
}
