package com.arcadia.DataQualityDashboard.service;

import java.io.File;

public interface DataQualityResultService {
    void saveCompletedResult(File resultJsonFile, Long scanId);

    void saveFailedResult(Long scanId, String errorMessage);
}
