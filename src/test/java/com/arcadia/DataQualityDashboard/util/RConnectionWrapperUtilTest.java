package com.arcadia.DataQualityDashboard.util;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.model.DbSettings;
import org.junit.jupiter.api.Test;

import static com.arcadia.DataQualityDashboard.model.ScanStatus.IN_PROGRESS;
import static com.arcadia.DataQualityDashboard.service.TestProperties.dqdDatabaseProperties;
import static org.junit.jupiter.api.Assertions.assertEquals;

class RConnectionWrapperUtilTest {
    @Test
    void createDataQualityCheckCommand() {
        DbSettings dbSettings = DbSettings.builder()
                .dbType("sql server")
                .server("localhost")
                .port(1433)
                .database("cdm_test_53")
                .schema("dbo")
                .user("test")
                .password("test")
                .build();
        DataQualityScan dataQualityScan = DataQualityScan.builder()
                .id(1L)
                .username("perseus")
                .project("Test")
                .statusCode(IN_PROGRESS.getCode())
                .statusName(IN_PROGRESS.getName())
                .dbSettings(dbSettings)
                .build();
        dbSettings.setDataQualityScan(dataQualityScan);

        String dbType = "postgresql";
        String server = "localhost";
        String schema = "test";
        int threadCount = 1;

        String command = RConnectionWrapperUtil.createDataQualityCheckCommand(
                dataQualityScan,
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
                                "cdm_user = \"test\", " +
                                "cdm_password = \"test\", " +
                                "scanId = 1, " +
                                "threadCount = 1, " +
                                "cdmSourceName = \"Test\", " +
                                "dqd_dataType = \"postgresql\", " +
                                "dqd_server = \"shareddb/shared\", " +
                                "dqd_port = 5432, " +
                                "dqd_dataBaseSchema = \"dqd\", " +
                                "dqd_user = \"dqd\", " +
                                "dqd_password = \"password\", " +
                                "username = \"perseus\", " +
                                "httppath = \"null\"" +
                         ")";
        assertEquals(expected, command);
    }
}