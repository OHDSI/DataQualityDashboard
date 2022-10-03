package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.config.DqdDatabaseProperties;
import com.arcadia.DataQualityDashboard.config.RServeProperties;

import java.util.List;

public class TestProperties {
    public static final RServeProperties rServerProperties = new RServeProperties(
            "C:/Program Files/R/R-4.0.3/bin/x64/R.exe",
            "127.0.0.1",
            6311,
            false
    );

    public static final List<String> loadScripts = List.of(
            "R/data-quality-check.R",
            "R/dqd-database-manager.R",
            "R/execution.R"
    );

    public static DqdDatabaseProperties dqdDatabaseProperties = new DqdDatabaseProperties(
            "postgresql",
            "localhost",
            5432,
            "shared",
            "dqd",
            "dqd",
            "password"
    );
}
