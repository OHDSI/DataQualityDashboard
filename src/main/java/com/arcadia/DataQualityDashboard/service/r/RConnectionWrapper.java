package com.arcadia.DataQualityDashboard.service.r;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.service.response.TestConnectionResultResponse;

import java.io.Closeable;
import java.util.List;

public interface RConnectionWrapper extends Closeable {
    void loadScript(String path);

    void loadScripts(List<String> scriptsPaths);

    TestConnectionResultResponse testConnection(DbSettings dbSettings);

    String checkDataQuality(DataQualityScan scan);

    String checkDataQuality(DataQualityScan scan, int threadCount);

    void close();
}
