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

import java.util.Optional;

import static com.arcadia.DataQualityDashboard.model.ScanStatus.IN_PROGRESS;
import static org.junit.jupiter.api.Assertions.assertEquals;

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
                resultRepository,
                processService
        );
    }

    @Test
    void foundScanById() {
        DataQualityScan scan = createTestScan();
        Mockito.when(scanRepository.findById(scan.getId())).thenReturn(Optional.of(scan));
        DataQualityScan scanById = dataQualityService.findScanById(scan.getId(), scan.getUsername());

        assertEquals(scan, scanById);
    }

    public static DataQualityScan createTestScan() {
        return DataQualityScan.builder()
                .id(1L)
                .username("Perseus")
                .project("Data Quality")
                .statusCode(IN_PROGRESS.getCode())
                .statusName(IN_PROGRESS.getName())
                .dbSettings(createTestDbSettings())
                .build();
    }

    public static DbSettings createTestDbSettings() {
        return DbSettings.builder()
                .dbType("sql server")
                .server("822JNJ16S03V")
                .port(1433)
                .database("CDM_CPRD")
                .schema("dbo")
                .user("cdm_builder")
                .password("builder1!")
                .build();
    }
}