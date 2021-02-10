package com.arcadia.DataQualityDashboard.dto;

import lombok.Data;
import lombok.NonNull;

@Data
public class MessageToUser {

    @NonNull
    private final String userId;

    @NonNull
    private final String payload;
}
