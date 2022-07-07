package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;

import java.util.concurrent.Future;

public interface DataQualityProcessService {
    Future<Void> runCheckDataQualityProcess(DataQualityScan dataQualityScan);
}
