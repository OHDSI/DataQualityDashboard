package com.arcadia.DataQualityDashboard.util;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.service.request.FileSaveRequest;
import org.springframework.core.io.FileSystemResource;

import java.nio.file.Path;

public class FileSaveRequestUtil {
    public static final String DATA_KEY = "data-quality";

    public static FileSaveRequest createFileSaveRequest(Path resultJsonFile, DataQualityScan scan) {
        FileSystemResource resource = new FileSystemResource(resultJsonFile);
        return new FileSaveRequest(scan.getUsername(), DATA_KEY, resource);
    }
}
