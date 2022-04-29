package com.arcadia.DataQualityDashboard.util;

import java.io.File;

import static java.lang.String.format;
import static org.apache.commons.lang3.RandomStringUtils.random;

public class FileUtil {
    private static final int GENERATED_NAME_LENGTH = 30;

    public static final String DATA_QUALITY_CHECK_RESULTS_JSON_LOCATION = "results";

    public static String generateRandomFileName() {
        return random(GENERATED_NAME_LENGTH, true, false);
    }

    public static File createDirectory(String name) {
        File directory = new File(name);
        if (!directory.exists()) {
            directory.mkdirs();
        }
        return directory;
    }

    public static String toResultJsonFilePath(String name) {
        return format("%s/%s.json", DATA_QUALITY_CHECK_RESULTS_JSON_LOCATION, name);
    }
}
