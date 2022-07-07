package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.service.request.FileSaveRequest;
import com.arcadia.DataQualityDashboard.service.response.FileSaveResponse;
import org.springframework.core.io.ByteArrayResource;

public interface FilesManagerService {
    ByteArrayResource getFile(Long userDataId);

    FileSaveResponse saveFile(FileSaveRequest request);

    void deleteFile(String key);
}
