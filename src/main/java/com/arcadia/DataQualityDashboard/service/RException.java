package com.arcadia.DataQualityDashboard.service;

public class RException extends Exception {

    public RException(String message) {
        super(message);
    }

    public RException(String message, Throwable cause) {
        super(message, cause);
    }
}
