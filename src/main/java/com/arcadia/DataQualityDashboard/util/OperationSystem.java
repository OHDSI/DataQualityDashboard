package com.arcadia.DataQualityDashboard.util;

import org.apache.commons.lang3.SystemUtils;

public class OperationSystem {

    public static boolean isUnix() {
        return SystemUtils.IS_OS_UNIX;
    }

    public static String getCurrentPath() {
        return System.getProperty("user.dir");
    }
}
