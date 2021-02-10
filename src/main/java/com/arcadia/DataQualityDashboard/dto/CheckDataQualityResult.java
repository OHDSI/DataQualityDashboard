package com.arcadia.DataQualityDashboard.dto;

import lombok.Data;
import lombok.NonNull;

@Data
public class CheckDataQualityResult {

    @NonNull
    private final Boolean successfully;

    @NonNull
    private final String payload;
}
