package com.arcadia.DataQualityDashboard.service.error;

public class DbTypeNotSupportedException extends BadRequestException {
    public DbTypeNotSupportedException() {
        super("Database type not supported");
    }
}
