package com.arcadia.DataQualityDashboard.dto;

import lombok.Data;
import lombok.NonNull;

@Data
public class DbSettings {

    @NonNull
    private final String dbType;

    @NonNull
    private final String server;

    @NonNull
    private final Integer port;

    @NonNull
    private final String database;

    @NonNull
    private final String schema;

    @NonNull
    private final String user;

    @NonNull
    private final String password;
}
