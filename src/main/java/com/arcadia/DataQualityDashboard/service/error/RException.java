package com.arcadia.DataQualityDashboard.service.error;

public class RException extends RuntimeException {

    public RException(String message) {
        super(message);
    }

    public RException(String message, Throwable cause) {
        super(message, cause);
    }
}
