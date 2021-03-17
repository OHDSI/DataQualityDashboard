package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.dto.DbSettings;
import com.arcadia.DataQualityDashboard.properties.RServeProperties;
import com.arcadia.DataQualityDashboard.properties.StorageProperties;

import java.util.List;

public class TestProperties {

    public static final RServeProperties rServerProperties = new RServeProperties(
            "C:/Program Files/R/R-4.0.3/bin/x64/R.exe",
            "127.0.0.1",
            6311
    );

    public static final String uploadsLocation = "./uploads";

    public static final StorageProperties storageProperties = new StorageProperties(uploadsLocation);

    public static final DbSettings dbSettings = new DbSettings(
            "sql server",
            "822JNJ16S03V",
            1433,
            "CDM_CPRD",
            "dbo",
            "cdm_builder",
            "builder1!"
    );

    public static final List<String> loadScripts = List.of(
            "R/rServer.R",
            "R/messageSender.R",
            "R/execution.R"
    );
}
