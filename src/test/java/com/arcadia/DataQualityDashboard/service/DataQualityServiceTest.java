package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.repository.DataQualityLogRepository;
import com.arcadia.DataQualityDashboard.repository.DataQualityResultRepository;
import com.arcadia.DataQualityDashboard.repository.DataQualityScanRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mockito;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.web.server.ResponseStatusException;

import java.util.Optional;

import static com.arcadia.DataQualityDashboard.model.ScanStatus.IN_PROGRESS;
import static java.lang.String.format;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

@ExtendWith(SpringExtension.class)
public class DataQualityServiceTest {
    @MockBean
    DataQualityScanRepository scanRepository;

    @MockBean
    DataQualityLogRepository logRepository;

    @MockBean
    DataQualityResultRepository resultRepository;

    @MockBean
    DataQualityProcessService processService;

    DataQualityService dataQualityService;

    @BeforeEach
    void setUp() {
        dataQualityService = new DataQualityServiceImpl(
                scanRepository,
                logRepository,
                resultRepository
        );
    }

    @Test
    void foundScanById() {
        DataQualityScan scan = createTestScan();
        Mockito.when(scanRepository.findById(scan.getId())).thenReturn(Optional.of(scan));
        DataQualityScan scanById = dataQualityService.findScanById(scan.getId(), scan.getUsername());

        assertEquals(scan, scanById);
    }

    @Test
    void notFoundScanById() {
        DataQualityScan scan = createTestScan();
        long id = scan.getId() + 1;
        Mockito.when(scanRepository.findById(id)).thenReturn(Optional.empty());

        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> dataQualityService.findScanById(id, scan.getUsername())
        );
        assertEquals(format("404 NOT_FOUND \"Data Quality Scan not found by id %d\"", id), exception.getMessage());
    }

    @Test
    void foundScanByIdButForbidden() {
        DataQualityScan scan = createTestScan();
        Mockito.when(scanRepository.findById(scan.getId())).thenReturn(Optional.of(scan));
        String username = "Achilles";
        ResponseStatusException exception = assertThrows(
                ResponseStatusException.class,
                () -> dataQualityService.findScanById(scan.getId(), username)
        );
        assertEquals("403 FORBIDDEN \"Forbidden to get Data Quality Scan for other user\"", exception.getMessage());
    }

    public static DataQualityScan createTestScan() {
        DbSettings dbSettings = createTestDbSettings();
        DataQualityScan result = DataQualityScan.builder()
                .id(1L)
                .username("Perseus")
                .project("Test")
                .statusCode(IN_PROGRESS.getCode())
                .statusName(IN_PROGRESS.getName())
                .dbSettings(dbSettings)
                .build();
        dbSettings.setDataQualityScan(result);

        return result;
    }

    public static DbSettings createTestDbSettings() {
        return DbSettings.builder()
                .dbType("sql server")
                .server("")
                .port(1433)
                .database("cdm_test_53")
                .schema("dbo")
                .user("")
                .password("")
                .build();
    }
}