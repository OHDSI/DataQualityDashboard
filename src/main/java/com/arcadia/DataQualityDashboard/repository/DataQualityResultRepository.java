package com.arcadia.DataQualityDashboard.repository;

import com.arcadia.DataQualityDashboard.model.DataQualityResult;
import org.springframework.data.repository.CrudRepository;

import java.util.Optional;

public interface DataQualityResultRepository extends CrudRepository<DataQualityResult, Long> {
    Optional<DataQualityResult> findByDataQualityScanId(Long scanId);
}
