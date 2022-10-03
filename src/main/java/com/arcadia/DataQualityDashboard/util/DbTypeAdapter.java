package com.arcadia.DataQualityDashboard.util;

import com.arcadia.DataQualityDashboard.service.error.DbTypeNotSupportedException;

import java.util.List;
import java.util.Set;

import static java.lang.String.format;

public class DbTypeAdapter {
    private static final Set<String> dbTypes = Set.of(
            "sql server",
            "postgresql",
            "oracle",
            "redshift"
    );

    private static final List<String> dbRequireSchema = List.of(
            "postgresql",
            "oracle"
    );

    public static String adaptDbType(String value) throws DbTypeNotSupportedException {
        for (String dbType : dbTypes) {
            if (value.equalsIgnoreCase(dbType)) {
                return dbType;
            }
        }

        throw new DbTypeNotSupportedException();
    }

    public static String adaptServer(String dbType, String server, String database) {
        if (dbRequireSchema.contains(dbType)) {
            return format("%s/%s", server, database);
        } else {
            return server;
        }
    }

    public static String adaptDataBaseSchema(String database, String schema) {
        return format("%s.%s", database, schema);
    }
}
