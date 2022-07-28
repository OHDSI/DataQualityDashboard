package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.service.error.DbTypeNotSupportedException;
import com.arcadia.DataQualityDashboard.service.error.RException;
import com.arcadia.DataQualityDashboard.service.r.RConnectionCreatorImpl;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

import static com.arcadia.DataQualityDashboard.service.DataQualityServiceTest.createTestScan;
import static com.arcadia.DataQualityDashboard.service.TestProperties.dqdDatabaseProperties;
import static com.arcadia.DataQualityDashboard.service.TestProperties.rServerProperties;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class RConnectionWrapperTest {

    @Disabled
    @Test
    void dataQualityCheck() throws RException, IOException {
        RConnectionWrapper connection = new RConnectionCreatorImpl(rServerProperties, dqdDatabaseProperties)
                .createRConnection();
        DataQualityScan scan = createTestScan();
        String result = connection.checkDataQuality(scan);
        connection.close();

        assertNotNull(result);

        System.out.println(result);
        BufferedWriter writer = new BufferedWriter(new FileWriter("uploads/result.json"));
        writer.write(result);
        writer.close();
    }

    @Disabled
    @Test
    void performanceTest() throws RException, DbTypeNotSupportedException {
        int[] threadCounts = {1, 2, 3, 4, 5, 7};

        RConnectionWrapper connection = new RConnectionCreatorImpl(rServerProperties, dqdDatabaseProperties)
                .createRConnection();

        for (int threadCount : threadCounts) {
            long startTime = System.currentTimeMillis();
            DataQualityScan scan = createTestScan();
            String result = connection.checkDataQuality(scan, threadCount);
            long durationInSeconds = (System.currentTimeMillis() - startTime) / 1000;

            System.out.printf("%d threads: %d seconds%n", threadCount, durationInSeconds);

            assertNotNull(result);
        }

        connection.close();
    }
}
