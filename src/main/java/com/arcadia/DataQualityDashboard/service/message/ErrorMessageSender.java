package com.arcadia.DataQualityDashboard.service.message;

import com.arcadia.DataQualityDashboard.dto.ProgressNotificationStatus;
import org.springframework.stereotype.Service;

@Service
public class ErrorMessageSender implements MessageSender {

    @Override
    public ProgressNotificationStatus getStatus() {
        return ProgressNotificationStatus.FAILED;
    }
}
