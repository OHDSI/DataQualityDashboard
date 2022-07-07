package com.arcadia.DataQualityDashboard.util;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

class OperationSystemTest {

    @Disabled
    @Test
    void getCurrentPath() {
        String currentPath = OperationSystem.getCurrentPath();
        System.out.println(currentPath);
    }
}