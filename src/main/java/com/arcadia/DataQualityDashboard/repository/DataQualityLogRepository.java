package com.arcadia.DataQualityDashboard.repository;

import com.arcadia.DataQualityDashboard.model.DataQualityLog;
import org.springframework.data.repository.CrudRepository;

import java.util.List;

public interface DataQualityLogRepository extends CrudRepository<DataQualityLog, Long> {
    List<DataQualityLog> findAllByDataQualityScanId(Long scanId);
}
