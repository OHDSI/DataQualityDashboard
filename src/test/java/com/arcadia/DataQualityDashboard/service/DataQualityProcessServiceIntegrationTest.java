package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DataQualityLog;
import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.repository.DataQualityLogRepository;
import com.arcadia.DataQualityDashboard.repository.DataQualityResultRepository;
import com.arcadia.DataQualityDashboard.repository.DataQualityScanRepository;
import com.arcadia.DataQualityDashboard.service.error.RException;
import com.arcadia.DataQualityDashboard.service.r.RConnectionCreator;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import com.arcadia.DataQualityDashboard.service.response.FileSaveResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.junit.jupiter.SpringExtension;
import org.springframework.web.client.RestClientException;

import java.util.List;

import static com.arcadia.DataQualityDashboard.model.ScanStatus.*;
import static com.arcadia.DataQualityDashboard.service.DataQualityServiceTest.createTestDbSettings;
import static com.arcadia.DataQualityDashboard.util.FileSaveRequestUtil.DATA_KEY;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest
@ExtendWith(SpringExtension.class)
class DataQualityProcessServiceIntegrationTest {
    @MockBean
    RConnectionCreator rConnectionCreator;

    @MockBean
    RConnectionWrapper rConnectionWrapper;

    @MockBean
    FilesManagerService filesManagerService;

    @Autowired
    DataQualityScanRepository scanRepository;

    @Autowired
    DataQualityResultRepository resultRepository;

    @Autowired
    DataQualityLogRepository logRepository;

    DataQualityProcessService dataQualityProcessService;

    @BeforeEach
    void setUp() {
        DataQualityResultServiceImpl resultService = new DataQualityResultServiceImpl(
                scanRepository,
                resultRepository,
                logRepository
        );
        dataQualityProcessService = new DataQualityProcessServiceImpl(
                rConnectionCreator,
                resultService,
                filesManagerService
        );
    }

    @Test
    void runCheckDataQualityProcess() {
        DataQualityScan scan = scanRepository.saveAndFlush(createTestScan());

        Mockito.when(rConnectionCreator.createRConnection()).thenReturn(rConnectionWrapper);
        String resultJson = "{}";
        Mockito.when(rConnectionWrapper.checkDataQuality(scan)).thenReturn(resultJson);
        FileSaveResponse fileSaveResponse = FileSaveResponse.builder()
                .id(1L)
                .username(scan.getUsername())
                .dataKey(DATA_KEY)
                .build();
        Mockito.when(filesManagerService.saveFile(Mockito.any())).thenReturn(fileSaveResponse);

        dataQualityProcessService.runCheckDataQualityProcess(scan);

        DataQualityScan scanFromDb = scanRepository.findById(scan.getId()).get();
        List<DataQualityLog> logs = logRepository.findAllByDataQualityScanId(scanFromDb.getId());

        assertEquals(scan.getId(), scanFromDb.getId());
        assertEquals(scanFromDb.getStatusCode(), COMPLETED.getCode());
        assertEquals(scanFromDb.getStatusName(), COMPLETED.getName());
        assertTrue(logs.stream().anyMatch(log -> log.getMessage().equals("Result json file successfully saved")));
    }

    @Test
    void fileManagerServiceThrowError() {
        DataQualityScan scan = scanRepository.saveAndFlush(createTestScan());

        Mockito.when(rConnectionCreator.createRConnection()).thenReturn(rConnectionWrapper);
        String resultJson = "{}";
        Mockito.when(rConnectionWrapper.checkDataQuality(scan)).thenReturn(resultJson);
        String errorMessage = "Test error";
        Mockito.when(filesManagerService.saveFile(Mockito.any())).thenThrow(new RestClientException(errorMessage));

        dataQualityProcessService.runCheckDataQualityProcess(scan);

        DataQualityScan scanFromDb = scanRepository.findById(scan.getId()).get();
        List<DataQualityLog> logs = logRepository.findAllByDataQualityScanId(scanFromDb.getId());

        assertEquals(scan.getId(), scanFromDb.getId());
        assertEquals(scanFromDb.getStatusCode(), FAILED.getCode());
        assertEquals(scanFromDb.getStatusName(), FAILED.getName());
        assertTrue(logs.stream().anyMatch(log -> log.getMessage().equals(errorMessage)));
    }

    @Test
    void rConnectionWrapperThrowError() {
        DataQualityScan scan = scanRepository.saveAndFlush(createTestScan());

        Mockito.when(rConnectionCreator.createRConnection()).thenReturn(rConnectionWrapper);
        String errorMessage = "Test Error";
        Mockito.when(rConnectionWrapper.checkDataQuality(scan)).thenThrow(new RException(errorMessage));

        dataQualityProcessService.runCheckDataQualityProcess(scan);

        DataQualityScan scanFromDb = scanRepository.findById(scan.getId()).get();
        List<DataQualityLog> logs = logRepository.findAllByDataQualityScanId(scanFromDb.getId());

        assertEquals(scan.getId(), scanFromDb.getId());
        assertEquals(scanFromDb.getStatusCode(), FAILED.getCode());
        assertEquals(scanFromDb.getStatusName(), FAILED.getName());
        assertTrue(logs.stream().anyMatch(log -> log.getMessage().equals(errorMessage)));
    }

    public static DataQualityScan createTestScan() {
        DbSettings dbSettings = createTestDbSettings();
        DataQualityScan result = DataQualityScan.builder()
                .username("Perseus")
                .project("Data Quality")
                .statusCode(IN_PROGRESS.getCode())
                .statusName(IN_PROGRESS.getName())
                .dbSettings(dbSettings)
                .build();
        dbSettings.setDataQualityScan(result);

        return result;
    }
}