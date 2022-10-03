package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.service.error.RException;
import com.arcadia.DataQualityDashboard.service.r.RConnectionCreator;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mockito;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import static com.arcadia.DataQualityDashboard.service.DataQualityServiceTest.createTestScan;

@ExtendWith(SpringExtension.class)
public class DataQualityProcessServiceTest {
    @MockBean
    DataQualityResultService resultService;

    @MockBean
    RConnectionCreator rConnectionCreator;

    @MockBean
    RConnectionWrapper rConnectionWrapper;

    @MockBean
    FilesManagerService filesManagerService;

    DataQualityProcessService dataQualityProcessService;

    @BeforeEach
    void setUp() {
        dataQualityProcessService = new DataQualityProcessServiceImpl(
                rConnectionCreator,
                resultService,
                filesManagerService
        );
    }

    @Test
    void userAbortProcess() {
        DataQualityScan scan = createTestScan();

        Mockito.when(rConnectionCreator.createRConnection()).thenReturn(rConnectionWrapper);
        String errorMessage = "Process was aborted by User";
        Mockito.when(rConnectionWrapper.checkDataQuality(scan)).thenThrow(new RException(errorMessage));

        dataQualityProcessService.runCheckDataQualityProcess(scan);

        Mockito.verify(resultService, Mockito.never()).saveFailedResult(Mockito.eq(scan.getId()), Mockito.eq(errorMessage));
    }

    @Test
    void rConnectionWrapperSetError() {
        DataQualityScan scan = createTestScan();

        Mockito.when(rConnectionCreator.createRConnection()).thenReturn(rConnectionWrapper);
        String errorMessage = "Test error";
        Mockito.when(rConnectionWrapper.checkDataQuality(scan)).thenThrow(new RException(errorMessage));

        dataQualityProcessService.runCheckDataQualityProcess(scan);

        Mockito.verify(resultService).saveFailedResult(Mockito.eq(scan.getId()), Mockito.eq(errorMessage));
    }
}
