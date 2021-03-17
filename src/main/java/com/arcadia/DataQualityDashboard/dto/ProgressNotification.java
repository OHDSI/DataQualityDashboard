package com.arcadia.DataQualityDashboard.dto;

import lombok.Data;
import lombok.NonNull;

@Data
public class ProgressNotification {

    @NonNull
    private final String message;

    @NonNull
    private final ProgressNotificationStatus status;
}
