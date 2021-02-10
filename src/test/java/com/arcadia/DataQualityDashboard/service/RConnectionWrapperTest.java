package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.dto.DbSettings;
import com.arcadia.DataQualityDashboard.properties.RServeProperties;
import lombok.SneakyThrows;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class RConnectionWrapperTest {
    private RConnectionWrapper rConnectionWrapper;

    private final RServeProperties properties = new RServeProperties(
            "",
            "10.110.1.7",
            6311
    );

    private final DbSettings dbSettings = new DbSettings(
            "sql server",
            "822JNJ16S03V",
            1433,
            "CDM_CPRD",
            "dbo",
            "cdm_builder",
            "builder1!"
    );

    @SneakyThrows
    @BeforeEach
    void setUp() {
        RConnectionCreator creator = new RConnectionCreator(properties);
        rConnectionWrapper = creator.createRConnection();
        rConnectionWrapper.loadScripts();
    }

    @AfterEach
    void tearDown() {
        rConnectionWrapper.close();
    }

    @Test
    void loadScripts() {
        // Loading in setUp method
    }

    @Test
    void dataQualityCheck() throws RException, DbTypeNotSupportedException {
        String result = rConnectionWrapper.checkDataQuality(dbSettings, "");
        assertNotNull(result);
    }
}
