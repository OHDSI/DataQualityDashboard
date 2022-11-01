package com.arcadia.DataQualityDashboard.model;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum ScanStatus {
    IN_PROGRESS(1, "IN_PROGRESS"),
    COMPLETED(2, "COMPLETED"),
    ABORTED(3, "ABORTED"),
    FAILED(4, "FAILED");

    private final int code;
    private final String name;
}
