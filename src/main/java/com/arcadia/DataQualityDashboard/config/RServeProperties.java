package com.arcadia.DataQualityDashboard.config;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Data
@NoArgsConstructor
@AllArgsConstructor
@ConfigurationProperties(prefix = "rserve")
public class RServeProperties {
    private String path; /* For Windows */
    private String host;
    private int port;
    private boolean unix;
}
