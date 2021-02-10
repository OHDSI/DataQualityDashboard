package com.arcadia.DataQualityDashboard.service.message;

import com.arcadia.DataQualityDashboard.dto.ProgressNotificationStatus;
import org.springframework.stereotype.Service;

@Service
public class CompleteMessageSender implements MessageSender {

    @Override
    public ProgressNotificationStatus getStatus() {
        return ProgressNotificationStatus.FINISHED;
    }
}
