package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.service.error.RException;
import com.arcadia.DataQualityDashboard.service.r.RConnectionCreator;
import com.arcadia.DataQualityDashboard.service.r.RConnectionCreatorImpl;
import com.arcadia.DataQualityDashboard.service.r.RConnectionWrapper;
import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.Test;

import static com.arcadia.DataQualityDashboard.service.TestProperties.rServerProperties;

class RConnectionCreatorTest {

    @Disabled
    @Test
    void createRConnection() throws RException {
        RConnectionCreator creator = new RConnectionCreatorImpl(rServerProperties);

        RConnectionWrapper connection = creator.createRConnection();

        connection.close();
    }

    @Disabled
    @Test
    void createMultipleRConnection() throws RException {
        RConnectionCreator creator = new RConnectionCreatorImpl(rServerProperties);

        RConnectionWrapper connection1 = creator.createRConnection();
        RConnectionWrapper connection2 = creator.createRConnection();

        connection1.close();
        connection2.close();
    }
}
