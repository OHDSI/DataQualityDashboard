package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.service.response.TestConnectionResultResponse;

public interface TestConnectionService {
    TestConnectionResultResponse testConnection(DbSettings dbSettings);
}
