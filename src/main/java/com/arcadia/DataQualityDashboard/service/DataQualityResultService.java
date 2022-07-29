package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.service.response.FileSaveResponse;

public interface DataQualityResultService {
    void saveCompletedResult(FileSaveResponse fileSaveResponse, Long scanId);

    void saveFailedResult(Long scanId, String errorMessage);
}
