package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.dto.DbSettings;
import com.arcadia.DataQualityDashboard.properties.RServeProperties;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertNotNull;

class RConnectionWrapperTest {

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

    @Test
    void loadScripts() {
        RConnectionCreator creator = new RConnectionCreator(properties);
        RConnectionWrapper connection = creator.createRConnection();
        connection.loadScripts();
        connection.close();
    }

    @Test
    void dataQualityCheck() throws RException, DbTypeNotSupportedException {
        RConnectionCreator creator = new RConnectionCreator(properties);
        RConnectionWrapper connection = creator.createRConnection();
        String result = connection.checkDataQuality(dbSettings, "");
        connection.close();

        assertNotNull(result);
    }
}
