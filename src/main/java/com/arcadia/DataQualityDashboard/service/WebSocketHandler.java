package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.dto.MessageToUser;
import com.arcadia.DataQualityDashboard.dto.ProgressNotificationStatus;
import com.arcadia.DataQualityDashboard.service.message.MessageSender;
import com.google.gson.Gson;
import lombok.SneakyThrows;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class WebSocketHandler extends TextWebSocketHandler {

    private final Map<ProgressNotificationStatus, MessageSender> senderMap;

    private final Map<String, WebSocketSession> sessions = new ConcurrentHashMap<>();

    @Autowired
    public WebSocketHandler(List<MessageSender> senderList) {
        this.senderMap = senderList
                .stream()
                .collect(Collectors.toMap(MessageSender::getStatus, Function.identity()));
    }

    @SneakyThrows
    @Override
    public void handleTextMessage(WebSocketSession session, TextMessage message) {
        Gson gson = new Gson();
        MessageToUser messageToUser = gson.fromJson(message.getPayload(), MessageToUser.class);

        WebSocketSession destinationSession = sessions.get(messageToUser.getUserId());

        MessageSender sender = senderMap.get(ProgressNotificationStatus.IN_PROGRESS);
        sender.send(destinationSession, messageToUser.getPayload());
    }

    @SneakyThrows
    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        sessions.put(session.getId(), session);
        session.sendMessage(new TextMessage(session.getId()));
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
       sessions.remove(session.getId());
    }

    @SneakyThrows
    public void sendMessageToUser(String message, String userId) {
        sendMessageToUser(message, userId, ProgressNotificationStatus.IN_PROGRESS);
    }

    @SneakyThrows
    public void sendMessageToUser(String message, String userId, ProgressNotificationStatus status) {
        WebSocketSession session = sessions.get(userId);
        MessageSender sender = senderMap.get(status);
        sender.send(session, message);
    }
}
