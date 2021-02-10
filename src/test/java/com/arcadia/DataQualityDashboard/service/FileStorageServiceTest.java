package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.properties.StorageProperties;
import org.junit.jupiter.api.Test;

import java.io.File;
import java.io.IOException;
import java.nio.file.Path;
import java.nio.file.Paths;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class FileStorageServiceTest {

    private final String location = "./uploads";

    private final StorageProperties storageProperties = new StorageProperties(location);

    @Test
    void delete() throws IOException {
        FileStorageService storageService = new FileStorageService(storageProperties);

        String fileName = "test.txt";
        Path rootPath = Paths.get(location);
        String resolvedTestFileName = rootPath.resolve(fileName).toString();

        File testFile = new File(resolvedTestFileName);

        assertTrue(testFile.createNewFile());
        assertTrue(testFile.exists());

        storageService.delete(fileName);

        assertFalse(testFile.exists());
    }
}
