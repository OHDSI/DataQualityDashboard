package com.arcadia.DataQualityDashboard.service;

import org.junit.jupiter.api.Test;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;

import static com.arcadia.DataQualityDashboard.service.TestProperties.storageProperties;
import static com.arcadia.DataQualityDashboard.service.TestProperties.uploadsLocation;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class FileStorageServiceTest {

    @Test
    void delete() throws IOException {
        FileStorageService storageService = new FileStorageService(storageProperties);

        String fileName = "test.txt";
        Path rootPath = Paths.get(uploadsLocation);
        String resolvedTestFileName = rootPath.resolve(fileName).toString();

        File testFile = new File(resolvedTestFileName);

        assertTrue(testFile.createNewFile());
        assertTrue(testFile.exists());

        storageService.delete(fileName);

        assertFalse(testFile.exists());
    }
}
