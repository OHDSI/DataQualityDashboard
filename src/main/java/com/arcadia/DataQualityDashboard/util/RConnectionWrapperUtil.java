package com.arcadia.DataQualityDashboard.util;

import com.arcadia.DataQualityDashboard.config.DqdDatabaseProperties;
import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.model.DbSettings;

import static com.arcadia.DataQualityDashboard.util.DbTypeAdapter.adaptServer;

public class RConnectionWrapperUtil {
    public static String createDataQualityCheckCommand(DataQualityScan scan,
                                                       String cdmDbType,
                                                       String cdmServer,
                                                       String cdmSchema,
                                                       int threadCount,
                                                       DqdDatabaseProperties dqdDatabaseProperties) {
        DbSettings dbSettings = scan.getDbSettings();
        String dqdServer = adaptServer(
                dqdDatabaseProperties.getDbms(),
                dqdDatabaseProperties.getServer(),
                dqdDatabaseProperties.getDatabase()
        );
        return "dataQualityCheck(" +
                    "cdm_dataType = \"" + cdmDbType + "\", " +
                    "cdm_server = \"" + cdmServer + "\", " +
                    "cdm_port = " + dbSettings.getPort() + ", " +
                    "cdm_dataBaseSchema = \"" + cdmSchema + "\", " +
                    "cdm_user = \"" + dbSettings.getUser() + "\", " +
                    "cdm_password = \"" + dbSettings.getPassword() + "\", " +
                    "scanId = " + scan.getId() + ", " +
                    "threadCount = " + threadCount + ", " +
                    "cdmSourceName = \"" + scan.getProject() + "\", " +
                    "dqd_dataType = \"" + dqdDatabaseProperties.getDbms() + "\", " +
                    "dqd_server = \"" + dqdServer + "\", " +
                    "dqd_port = " + dqdDatabaseProperties.getPort() + ", " +
                    "dqd_dataBaseSchema = \"" + dqdDatabaseProperties.getSchema() + "\", " +
                    "dqd_user = \"" + dqdDatabaseProperties.getUser() + "\", " +
                    "dqd_password = \"" + dqdDatabaseProperties.getPassword() + "\"" +
                ")";
    }
}
