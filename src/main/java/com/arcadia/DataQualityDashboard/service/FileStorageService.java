package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.properties.StorageProperties;
import lombok.SneakyThrows;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import javax.annotation.PostConstruct;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Date;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import static com.arcadia.DataQualityDashboard.util.CompareDate.getDateDiffInHours;

@Service
public class FileStorageService implements StorageService {

    private final Path rootLocation;

    private final ConcurrentHashMap<String, Date> filesCreationDates = new ConcurrentHashMap<>();

    @Autowired
    public FileStorageService(StorageProperties storageProperties) {
        this.rootLocation = Paths.get(storageProperties.getLocation());
    }

    @SneakyThrows
    @Override
    @PostConstruct
    public void init() {
        Files.createDirectories(rootLocation);
    }

    @SneakyThrows
    @Override
    public String store(String fileName, String fileContent) {
        String resolvedFileName = rootLocation.resolve(fileName).toString();
        BufferedWriter writer = new BufferedWriter(new FileWriter(resolvedFileName, false));
        writer.write(fileContent);
        writer.close();
        filesCreationDates.put(fileName, new Date());

        return fileName;
    }

    @Override
    public Path load(String filename) {
        return rootLocation.resolve(filename);
    }

    @SneakyThrows(MalformedURLException.class)
    @Override
    public Resource loadAsResource(String filename) throws FileNotFoundException {
        Path file = load(filename);
        UrlResource resource = new UrlResource(file.toUri());

        if (resource.exists() && resource.isReadable()) {
            return resource;
        } else {
            throw new FileNotFoundException("File not found");
        }
    }

    public boolean delete(String fileName) {
        String resolvedFileName = rootLocation.resolve(fileName).toString();
        File file = new File(resolvedFileName);

        return file.delete();
    }

    /* 8 hours */
    @Scheduled(fixedRate = 1000 * 60 * 60 * 8)
    private void clearFileStorage() {
        Date currentDate = new Date();

        for (Map.Entry<String, Date> entry : filesCreationDates.entrySet()) {
            long diffInHours = getDateDiffInHours(currentDate, entry.getValue());

            if (diffInHours > 1) {
                delete(entry.getKey());
            }
        }
    }
}
