package com.arcadia.DataQualityDashboard.service;

import java.util.Set;

public class DbTypeAdapter {

    private static final Set<String> dbTypes = Set.of(
            "sql server",
            "postgresql",
            "oracle",
            "pdw",
            "redshift",
            "netezza",
            "impala",
            "hive",
            "bigquery",
            "sqlite"
    );

    public static String adaptDbType(String value) throws DbTypeNotSupportedException {
        for (String dbType : dbTypes) {
            if (value.equalsIgnoreCase(dbType)) {
                return dbType;
            }
        }

        throw new DbTypeNotSupportedException();
    }
}
