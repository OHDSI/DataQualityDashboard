package com.arcadia.DataQualityDashboard.config;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Data
@NoArgsConstructor
@AllArgsConstructor
@ConfigurationProperties(prefix = "dqd-database")
public class DqdDatabaseProperties {
    private String dbms;
    private String server;
    private int port;
    private String database;
    private String schema;
    private String user;
    private String password;
}
