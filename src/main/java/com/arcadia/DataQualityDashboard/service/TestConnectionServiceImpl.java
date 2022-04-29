package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.service.r.RConnectionCreator;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import com.arcadia.DataQualityDashboard.service.response.TestConnectionResultResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class TestConnectionServiceImpl implements TestConnectionService {
    private final RConnectionCreator rConnectionCreator;

    @Override
    public TestConnectionResultResponse testConnection(DbSettings dbSettings) {
        RConnectionWrapper rConnection = rConnectionCreator.createRConnection();
        return rConnection.testConnection(dbSettings);
    }
}
