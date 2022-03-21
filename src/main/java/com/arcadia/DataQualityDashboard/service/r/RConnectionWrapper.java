package com.arcadia.DataQualityDashboard.service.r;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;

import java.util.List;

public interface RConnectionWrapper {
    void loadScript(String path);

    void loadScripts(List<String> scriptsPaths);

    String checkDataQuality(DataQualityScan scan);

    String checkDataQuality(DataQualityScan scan, int threadCount);

    void close();
}
