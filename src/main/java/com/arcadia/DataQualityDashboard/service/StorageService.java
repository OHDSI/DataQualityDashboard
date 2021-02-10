package com.arcadia.DataQualityDashboard.service;

import org.springframework.core.io.Resource;

import java.io.FileNotFoundException;
import java.nio.file.Path;

public interface StorageService {

    void init();

    String store(String fileName, String fileContent);

    Path load(String filename);

    Resource loadAsResource(String filename) throws FileNotFoundException;
}
