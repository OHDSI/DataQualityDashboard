package com.arcadia.DataQualityDashboard.service.message;

import com.arcadia.DataQualityDashboard.dto.ProgressNotification;
import com.arcadia.DataQualityDashboard.dto.ProgressNotificationStatus;
import com.google.gson.Gson;
import lombok.SneakyThrows;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

public interface MessageSender {

    @SneakyThrows
    default void send(WebSocketSession session, String message){
        if (session != null) {
            ProgressNotification notification = new ProgressNotification(message, getStatus());
            Gson gson = new Gson();
            String json = gson.toJson(notification);

            session.sendMessage(new TextMessage(json));
        }
    }

    ProgressNotificationStatus getStatus();
}
