package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.config.DqdDatabaseProperties;
import com.arcadia.DataQualityDashboard.config.RServeProperties;

public class TestProperties {
    public static final RServeProperties rServerProperties = new RServeProperties(
            null,
            "localhost",
            6311,
            true
    );

    public static DqdDatabaseProperties dqdDatabaseProperties = new DqdDatabaseProperties(
            "postgresql",
            "shareddb",
            5432,
            "shared",
            "dqd",
            "dqd",
            "password"
    );
}
