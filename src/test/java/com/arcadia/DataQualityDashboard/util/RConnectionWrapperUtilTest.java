package com.arcadia.DataQualityDashboard.util;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import org.junit.jupiter.api.Test;

import static com.arcadia.DataQualityDashboard.service.DataQualityServiceTest.createTestScan;
import static com.arcadia.DataQualityDashboard.service.TestProperties.dqdDatabaseProperties;
import static org.junit.jupiter.api.Assertions.assertEquals;

class RConnectionWrapperUtilTest {
    @Test
    void createDataQualityCheckCommand() {
        DataQualityScan scan = createTestScan();
        String dbType = "postgresql";
        String server = "localhost";
        String schema = "test";
        int threadCount = 1;
        String command = RConnectionWrapperUtil.createDataQualityCheckCommand(
                scan,
                dbType,
                server,
                schema,
                threadCount,
                dqdDatabaseProperties
        );
        String expected = "dataQualityCheck(" +
                                "cdm_dataType = \"postgresql\", " +
                                "cdm_server = \"localhost\", " +
                                "cdm_port = 1433, " +
                                "cdm_dataBaseSchema = \"test\", " +
                                "cdm_user = \"cdm_builder\", " +
                                "cdm_password = \"builder1!\", " +
                                "scanId = 1, " +
                                "threadCount = 1, " +
                                "cdmSourceName = \"Data Quality\", " +
                                "dqd_dataType = \"postgresql\", " +
                                "dqd_server = \"localhost/shared\", " +
                                "dqd_port = 5432, " +
                                "dqd_dataBaseSchema = \"dqd\", " +
                                "dqd_user = \"dqd\", " +
                                "dqd_password = \"password\"" +
                         ")";
        assertEquals(expected, command);
    }
}