package com.arcadia.DataQualityDashboard.service;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

import static com.arcadia.DataQualityDashboard.service.TestProperties.dbSettings;
import static com.arcadia.DataQualityDashboard.service.TestProperties.rServerProperties;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class RConnectionWrapperTest {

    @Disabled
    @Test
    void dataQualityCheck() throws RException, DbTypeNotSupportedException, IOException {
        RConnectionWrapper connection = new RConnectionCreator(rServerProperties)
                .createRConnection();

        String result = connection.checkDataQuality(dbSettings, "");
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

        RConnectionWrapper connection = new RConnectionCreator(rServerProperties)
                .createRConnection();

        for (int threadCount : threadCounts) {
            long startTime = System.currentTimeMillis();
            String result = connection.checkDataQuality(dbSettings, "", threadCount);
            long durationInSeconds = (System.currentTimeMillis() - startTime) / 1000;

            System.out.printf("%d threads: %d seconds%n", threadCount, durationInSeconds);

            assertNotNull(result);
        }

        connection.close();
    }
}
