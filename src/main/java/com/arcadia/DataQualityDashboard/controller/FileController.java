package com.arcadia.DataQualityDashboard.controller;

import com.arcadia.DataQualityDashboard.service.StorageService;
import lombok.AllArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.io.FileNotFoundException;

import static java.lang.String.format;
import static org.springframework.http.HttpHeaders.CONTENT_DISPOSITION;

@AllArgsConstructor
@RestController
@RequestMapping("/api")
public class FileController {

    private final StorageService storageService;

    @GetMapping("/download/{fileName:.+}")
    @ResponseBody
    public ResponseEntity<Resource> downloadFile(@PathVariable String fileName) {
        try {
            Resource resource = storageService.loadAsResource(fileName);
            return ResponseEntity
                    .ok()
                    .header(CONTENT_DISPOSITION, format("attachment; filename=\"%S\"", resource.getFilename()))
                    .body(resource);
        } catch (FileNotFoundException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage(), e);
        }
    }
}
