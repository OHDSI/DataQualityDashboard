package com.arcadia.DataQualityDashboard.service.error;

import org.springframework.web.server.ResponseStatusException;

import static org.springframework.http.HttpStatus.INTERNAL_SERVER_ERROR;

public class InternalServerErrorException extends ResponseStatusException {
    public InternalServerErrorException(String reason, Throwable cause) {
        super(INTERNAL_SERVER_ERROR, reason, cause);
    }
}
