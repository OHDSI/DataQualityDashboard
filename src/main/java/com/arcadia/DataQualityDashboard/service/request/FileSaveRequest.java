package com.arcadia.DataQualityDashboard.service.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.core.io.FileSystemResource;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FileSaveRequest {
    private String username;
    private String dataKey;
    private FileSystemResource file;
}
