package com.arcadia.DataQualityDashboard;

import com.arcadia.DataQualityDashboard.service.r.RConnectionCreator;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
@ConfigurationPropertiesScan
@Slf4j
public class DataQualityDashboardApplication {
	public static void main(String[] args) {
		SpringApplication.run(DataQualityDashboardApplication.class, args);
	}

	@Bean
	CommandLineRunner run(RConnectionCreator rConnectionCreator) {
		return args -> {
			if (rConnectionCreator.isUnix()) {
				try(RConnectionWrapper rConnection = rConnectionCreator.createRConnection()) {
					rConnection.loadScript(rConnectionCreator.getDownloadJdbcDriversScript());
					log.info("JDBC drivers successfully loaded to Rserve");
				} catch (Exception e) {
					log.error("Can not load JDBC drivers to Rserve: {}, stack trace: {}", e.getMessage(), e.getStackTrace());
				}
			}
		};
	}
}
