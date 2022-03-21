package com.arcadia.DataQualityDashboard.service.r;

import com.arcadia.DataQualityDashboard.config.RServeProperties;
import com.arcadia.DataQualityDashboard.service.error.RException;
import lombok.Getter;
import lombok.SneakyThrows;
import org.rosuda.REngine.Rserve.RConnection;
import org.rosuda.REngine.Rserve.RserveException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RConnectionCreatorImpl implements RConnectionCreator {
    private final String exeFilePath; /* For Windows */
    private final String host;
    private final int port;
    private volatile int currentPort; /* For Windows */

    @Getter
    private final boolean isUnix;

    @Getter
    private final List<String> loadScripts = List.of(
            "~/R/data-quality-check.R",
            "~/R/dqd-database-manager.R",
            "~/R/execution.R",
            "~/R/log-appender.R"
    );

    @Getter
    private final String downloadJdbcDriversScript =
            "~/R/download-jdbc-drivers.R";

    @Autowired
    public RConnectionCreatorImpl(RServeProperties properties) {
        exeFilePath = properties.getPath();
        host = properties.getHost();
        port = properties.getPort();
        isUnix = properties.isUnix();
        currentPort = port;
    }

    /* Multithreading
    * Unix: no problem, one Rserve instance can serve multiple calls.
    * Windows: Rserve can't create a separate process by forking the current process;
    * Create a new Rserve process for each thread (listening on a different port);
    * A new Rserve connection on the corresponding port has to be established as well. */
    @Override
    public RConnectionWrapper createRConnection() throws RException {
        try {
            RConnection connection;
            if (isUnix) {
                connection = new RConnection(host, port);
            } else {
                int currentPort = getAndIncrementCurrentPort();
                createRServeProcess(currentPort);
                connection = new RConnection(host, currentPort);
            }
            RConnectionWrapper connectionWrapper = new RConnectionWrapperImpl(connection, isUnix);
            if (!isUnix) {
                connectionWrapper.loadScript(downloadJdbcDriversScript);
            }
            connectionWrapper.loadScripts(loadScripts);

            return connectionWrapper;
        } catch (RserveException e) {
            throw new RException(e.getMessage(), e);
        }
    }

    /* For Windows */
    @SneakyThrows
    private void createRServeProcess(int port) {
        String cmd = String.format("%s -e \"library(Rserve);Rserve(port=%d)\"", exeFilePath, port);
        Runtime.getRuntime().exec(cmd);
    }

    /* For Windows */
    private synchronized int getAndIncrementCurrentPort() {
        int result = currentPort;
        currentPort++;
        return result;
    }
}
