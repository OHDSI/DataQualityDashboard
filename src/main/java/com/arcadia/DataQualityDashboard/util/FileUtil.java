package com.arcadia.DataQualityDashboard.util;

import lombok.SneakyThrows;

import java.nio.file.Files;
import java.nio.file.Path;

import static org.apache.commons.lang3.RandomStringUtils.random;

public class FileUtil {
    private static final int GENERATED_NAME_LENGTH = 30;

    public static final String RESULTS_JSON_LOCATION = "results";

    public static String generateRandomFileName() {
        return random(GENERATED_NAME_LENGTH, true, false);
    }

    @SneakyThrows
    public static void createDirectory(String name) {
        Path path = Path.of(name);
        if (!Files.exists(path)) {
            Files.createDirectories(path);
        }
    }
}
