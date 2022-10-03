package com.arcadia.DataQualityDashboard.service.r;

import com.arcadia.DataQualityDashboard.config.DqdDatabaseProperties;
import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.service.error.RException;
import com.arcadia.DataQualityDashboard.service.response.TestConnectionResultResponse;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import org.rosuda.REngine.REXP;
import org.rosuda.REngine.Rserve.RConnection;

import java.util.List;

import static com.arcadia.DataQualityDashboard.util.DbTypeAdapter.*;
import static com.arcadia.DataQualityDashboard.util.RConnectionWrapperUtil.createDataQualityCheckCommand;
import static java.lang.String.format;

@RequiredArgsConstructor
public class RConnectionWrapperImpl implements RConnectionWrapper {
    private static final int DEFAULT_THREAD_COUNT = 1;

    private final RConnection rConnection;

    @Getter
    private final boolean isUnix;

    private final DqdDatabaseProperties dqdDatabaseProperties;

    @Override
    @SneakyThrows
    public void loadScript(String path) {
        String cmd = format("source('%s')", path);
        REXP runResponse = rConnection.parseAndEval(toTryCmd(cmd));
        if (runResponse.inherits("try-error")) {
            throw new RException(runResponse.asString());
        }
    }

    @Override
    @SneakyThrows
    public void loadScripts(List<String> scriptsPaths) {
        for (String path : scriptsPaths) {
            loadScript(path);
        }
    }

    @SneakyThrows
    @Override
    public TestConnectionResultResponse testConnection(DbSettings dbSettings) {
        String dbType = adaptDbType(dbSettings.getDbType());
        String server = adaptServer(dbType, dbSettings.getServer(), dbSettings.getDatabase());
        String schema = adaptDataBaseSchema(dbSettings.getDatabase(), dbSettings.getSchema());
        String dqdCmd = format("testConnection(\"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\")",
                dbType,
                server,
                dbSettings.getPort(),
                schema,
                dbSettings.getUser(),
                dbSettings.getPassword()
        );
        REXP runResponse = rConnection.parseAndEval(toTryCmd(dqdCmd));
        if (runResponse.inherits("try-error")) {
            return TestConnectionResultResponse.builder()
                    .canConnect(false)
                    .message(runResponse.asString())
                    .build();
        }
        return TestConnectionResultResponse.builder()
                .canConnect(true)
                .build();
    }

    @Override
    public String checkDataQuality(DataQualityScan scan) {
        return checkDataQuality(scan, DEFAULT_THREAD_COUNT);
    }

    @Override
    @SneakyThrows
    public String checkDataQuality(DataQualityScan scan, int threadCount) {
        DbSettings dbSettings = scan.getDbSettings();
        String cdmDbType = adaptDbType(dbSettings.getDbType());
        String cdmServer = adaptServer(cdmDbType, dbSettings.getServer(), dbSettings.getDatabase());
        String cdmSchema = adaptDataBaseSchema(dbSettings.getDatabase(), dbSettings.getSchema());
        String dqdCmd = createDataQualityCheckCommand(
                scan,
                cdmDbType,
                cdmServer,
                cdmSchema,
                threadCount,
                dqdDatabaseProperties
        );
        REXP runResponse = rConnection.parseAndEval(toTryCmd(dqdCmd));
        if (runResponse.inherits("try-error")) {
            throw new RException(runResponse.asString());
        }

        return runResponse.asString();
    }

    @Deprecated
    @SneakyThrows
    public Integer getRServerPid() {
        String cmd = "Sys.getpid()";
        return rConnection.eval(cmd).asInteger();
    }

    @Deprecated
    @SneakyThrows
    public void abort(int pid) {
        rConnection.eval("tools::pskill("+ pid + ")");
        rConnection.eval("tools::pskill("+ pid + ", tools::SIGKILL)");

        this.close();
    }

    @Override
    @SneakyThrows
    public void close() {
        if (isUnix) {
            this.rConnection.close();
        } else {
            this.rConnection.shutdown();
        }
    }

    private String toTryCmd(String cmd) {
        return "try(eval(" + cmd + "),silent=TRUE)";
    }
}
