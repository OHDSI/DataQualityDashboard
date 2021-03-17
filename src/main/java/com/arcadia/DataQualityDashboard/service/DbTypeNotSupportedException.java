package com.arcadia.DataQualityDashboard.service;

public class DbTypeNotSupportedException extends Exception {

    public DbTypeNotSupportedException() {
        super("Database type not supported");
    }
}
