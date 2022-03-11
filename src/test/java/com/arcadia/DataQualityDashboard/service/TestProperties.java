package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.config.RServeProperties;

import java.util.List;

public class TestProperties {
    public static final RServeProperties rServerProperties = new RServeProperties(
            "C:/Program Files/R/R-4.0.3/bin/x64/R.exe",
            "127.0.0.1",
            6311
    );

    public static final List<String> loadScripts = List.of(
            "R/dqd.R",
            "R/dqd-database-manager.R",
            "R/execution.R"
    );
}
