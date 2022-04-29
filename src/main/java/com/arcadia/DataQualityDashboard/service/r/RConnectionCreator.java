package com.arcadia.DataQualityDashboard.service.r;

import com.arcadia.DataQualityDashboard.service.error.RException;

public interface RConnectionCreator {
    RConnectionWrapper createRConnection() throws RException;

    boolean isUnix();

    String getDownloadJdbcDriversScript();
}
