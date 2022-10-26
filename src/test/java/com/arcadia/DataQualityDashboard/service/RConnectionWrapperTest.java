package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.service.error.DbTypeNotSupportedException;
import com.arcadia.DataQualityDashboard.service.error.RException;
import com.arcadia.DataQualityDashboard.service.r.RConnectionCreatorImpl;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import com.arcadia.DataQualityDashboard.service.response.TestConnectionResultResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

import static com.arcadia.DataQualityDashboard.service.DataQualityServiceTest.createTestDbSettings;
import static com.arcadia.DataQualityDashboard.service.DataQualityServiceTest.createTestScan;
import static com.arcadia.DataQualityDashboard.service.TestProperties.dqdDatabaseProperties;
import static com.arcadia.DataQualityDashboard.service.TestProperties.rServerProperties;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RConnectionWrapperTest {
    RConnectionCreatorImpl connectionCreator = new RConnectionCreatorImpl(rServerProperties, dqdDatabaseProperties);

    @BeforeEach
    void setUp() {
        try(RConnectionWrapper connection = connectionCreator.createRConnection()) {
            connection.loadScript(connectionCreator.getDownloadJdbcDriversScript());
        } catch (RException rException) {
            System.out.println("Can not download JDBC drivers: " + rException.getMessage());
        }
    }

    @Disabled
    @Test
    void testConnection() {
        try(RConnectionWrapper connection = connectionCreator.createRConnection()) {
            DbSettings dbSettings = createTestDbSettings();
            TestConnectionResultResponse resultResponse = connection.testConnection(dbSettings);

            assertTrue(resultResponse.isCanConnect());
        }
    }

    @Disabled
    @Test
    void dataQualityCheck() throws RException, IOException {
        String result = null;

        try(RConnectionWrapper connection = connectionCreator.createRConnection()) {
            DataQualityScan scan = createTestScan();
            result = connection.checkDataQuality(scan);
        }

        assertNotNull(result);

        try(BufferedWriter writer = new BufferedWriter(new FileWriter("result.json"))) {
            writer.write(result);
        }
    }

    @Disabled
    @Test
    void performanceTest() throws RException, DbTypeNotSupportedException {
        int[] threadCounts = {1, 2, 3, 4, 5, 7};

        for (int threadCount : threadCounts) {
            try(RConnectionWrapper connection = connectionCreator.createRConnection()) {
                long startTime = System.currentTimeMillis();
                DataQualityScan scan = createTestScan();
                String result = connection.checkDataQuality(scan, threadCount);
                long durationInSeconds = (System.currentTimeMillis() - startTime) / 1000;
                System.out.printf("%d threads: %d seconds%n", threadCount, durationInSeconds);
                assertNotNull(result);
            }
        }
    }
}
