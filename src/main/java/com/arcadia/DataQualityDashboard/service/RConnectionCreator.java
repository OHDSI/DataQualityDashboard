package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.properties.RServeProperties;
import lombok.SneakyThrows;
import org.rosuda.REngine.Rserve.RConnection;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import static com.arcadia.DataQualityDashboard.util.OperationSystem.isUnix;

@Service
public class RConnectionCreator {

    /* For Windows */
    private final String path;

    private final String host;

    private final int port;

    /* For Windows */
    private volatile int currentPort;

    @Autowired
    public RConnectionCreator(RServeProperties properties) {
        path = properties.getPath();
        host = properties.getHost();
        port = properties.getPort();

        currentPort = port;
    }

    /* Multithreading
    * Unix: no problem, one Rserve instance can serve multiple calls.
    * Windows: Rserve can't create a separate process by forking the current process;
    * Create a new Rserve process for each thread (listening on a different port);
    * A new Rserve connection on the corresponding port has to be established as well. */
    @SneakyThrows
    public RConnectionWrapper createRConnection() {
        RConnection connection;

        if (isUnix()) {
            connection = new RConnection(host, port);
        } else {
            int currentPort = getAndIncrementCurrentPort();
            createRServeProcess(currentPort);
            connection = new RConnection(host, currentPort);
        }
        RConnectionWrapper connectionWrapper = new RConnectionWrapper(connection);
        connectionWrapper.loadScripts();

        return connectionWrapper;
    }

    @SneakyThrows
    private void createRServeProcess(int port) {
        String cmd = String.format("%s -e \"library(Rserve);Rserve(port=%d)\"", path, port);
        Runtime.getRuntime().exec(cmd);
    }

    private synchronized int getAndIncrementCurrentPort() {
        int result = currentPort;
        currentPort++;

        return result;
    }
}
