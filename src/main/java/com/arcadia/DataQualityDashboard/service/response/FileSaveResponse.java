package com.arcadia.DataQualityDashboard.service.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FileSaveResponse {
    private Long id;
    private String username;
    private String dataKey;
}
