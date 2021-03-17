package com.arcadia.DataQualityDashboard.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.google.gson.annotations.SerializedName;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public enum ProgressNotificationStatus {
    @SerializedName("1")
    IN_PROGRESS(1, "In progress"),
    @SerializedName("2")
    FINISHED(2, "Process finished"),
    @SerializedName("4")
    FAILED(4, "Process failed");

    private final int code;
    private final String description;
}
