package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.service.error.InternalServerErrorException;
import com.arcadia.DataQualityDashboard.service.r.RConnectionCreator;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import com.arcadia.DataQualityDashboard.service.response.TestConnectionResultResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class TestConnectionServiceImpl implements TestConnectionService {
    private final RConnectionCreator rConnectionCreator;

    @Override
    public TestConnectionResultResponse testConnection(DbSettings dbSettings) {
        try(RConnectionWrapper rConnection = rConnectionCreator.createRConnection()) {
            return rConnection.testConnection(dbSettings);
        } catch (Exception e) {
            log.error("Error when connect to r server: {}. Stack trace: {}", e.getMessage(), e.getStackTrace());
            throw new InternalServerErrorException("Error when connect to r server: " + e.getMessage(), e);
        }
    }
}
