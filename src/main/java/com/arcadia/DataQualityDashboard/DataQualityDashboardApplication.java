package com.arcadia.DataQualityDashboard;

import com.arcadia.DataQualityDashboard.service.r.RConnectionCreator;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.context.annotation.Bean;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@ConfigurationPropertiesScan
@EnableScheduling
public class DataQualityDashboardApplication {

	public static void main(String[] args) {
		SpringApplication.run(DataQualityDashboardApplication.class, args);
	}

	@Bean
	CommandLineRunner run(RConnectionCreator rConnectionCreator) {
		return args -> {
			RConnectionWrapper rConnection = rConnectionCreator.createRConnection();
			if (rConnection.isUnix()) {
				rConnection.downloadJdbcDrivers();
			}
		};
	}
}
