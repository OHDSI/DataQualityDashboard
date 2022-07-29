package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.service.r.RConnectionCreator;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import com.arcadia.DataQualityDashboard.service.response.TestConnectionResultResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR;

@Service
@RequiredArgsConstructor
public class TestConnectionServiceImpl implements TestConnectionService {
    private final RConnectionCreator rConnectionCreator;

    @Override
    public TestConnectionResultResponse testConnection(DbSettings dbSettings) {
        try {
            RConnectionWrapper rConnection = rConnectionCreator.createRConnection();
            return rConnection.testConnection(dbSettings);
        } catch (Exception e) {
            throw new ResponseStatusException(INTERNAL_SERVER_ERROR, "Can not get response from R server: " + e.getMessage(), e);
        }
    }
}
