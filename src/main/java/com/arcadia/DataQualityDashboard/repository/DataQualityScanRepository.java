package com.arcadia.DataQualityDashboard.repository;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DataQualityScanRepository extends JpaRepository<DataQualityScan, Long> {
}
