package com.arcadia.DataQualityDashboard.service;

import org.junit.jupiter.api.Test;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

import static com.arcadia.DataQualityDashboard.service.TestProperties.*;
import static java.lang.String.format;
import static org.junit.jupiter.api.Assertions.assertNotNull;

class RConnectionWrapperTest {

    @Test
    void loadScripts() throws RException {
        // Windows OS
        RConnectionWrapper connection = new RConnectionCreator(rServerProperties)
                .setLoadScripts(loadScripts)
                .createRConnection();

        connection.close();
    }

    @Test
    void dataQualityCheck() throws RException, DbTypeNotSupportedException, IOException {
        // Windows OS
        RConnectionWrapper connection = new RConnectionCreator(rServerProperties)
                .setLoadScripts(loadScripts)
                .createRConnection();

        String result = connection.checkDataQuality(dbSettings, "");
        connection.close();

        assertNotNull(result);

        System.out.println(result);
        BufferedWriter writer = new BufferedWriter(new FileWriter("uploads/result.json"));
        writer.write(result);
        writer.close();
    }

    @Test
    void performanceTest() throws RException, DbTypeNotSupportedException {
        int[] threadCounts = {1, 2, 3, 4, 5, 7, 9};

        RConnectionWrapper connection = new RConnectionCreator(rServerProperties)
                .setLoadScripts(loadScripts)
                .createRConnection();

        for (int threadCount : threadCounts) {
            long startTime = System.currentTimeMillis();
            String result = connection.checkDataQuality(dbSettings, "", threadCount);
            long durationInSeconds = (System.currentTimeMillis() - startTime) / 1000;
            System.out.println(format("%d threads: %d seconds", threadCount, durationInSeconds));
            assertNotNull(result);
        }
    }
}
