package com.arcadia.DataQualityDashboard;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

import static com.arcadia.DataQualityDashboard.util.OperationSystem.isUnix;

@SpringBootTest
class DataQualityDashboardApplicationTests {

    @Test
    void contextLoads() {
        System.out.printf("Is Unix: %b%n", isUnix());
    }

}
