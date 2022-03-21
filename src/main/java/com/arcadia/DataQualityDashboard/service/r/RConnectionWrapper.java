package com.arcadia.DataQualityDashboard.service.r;

import com.arcadia.DataQualityDashboard.model.DataQualityScan;
import com.arcadia.DataQualityDashboard.model.DbSettings;
import com.arcadia.DataQualityDashboard.service.error.RException;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.SneakyThrows;
import org.rosuda.REngine.REXP;
import org.rosuda.REngine.Rserve.RConnection;

import java.util.List;

import static com.arcadia.DataQualityDashboard.util.DbTypeAdapter.*;
import static java.lang.String.format;

@RequiredArgsConstructor
public class RConnectionWrapper {
    private static final int DEFAULT_THREAD_COUNT = 1;

    private final RConnection rConnection;

    @Getter
    private final boolean isUnix;

    @SneakyThrows
    public void loadScript(String path) {
        String cmd = format("source('%s')", path);
        REXP runResponse = rConnection.parseAndEval(toTryCmd(cmd));
        if (runResponse.inherits("try-error")) {
            throw new RException(runResponse.asString());
        }
    }

    @SneakyThrows
    public void loadScripts(List<String> scriptsPaths) {
        for (String path : scriptsPaths) {
            loadScript(path);
        }
    }

    public String checkDataQuality(DataQualityScan scan) {
        return checkDataQuality(scan, DEFAULT_THREAD_COUNT);
    }

    @SneakyThrows
    public String checkDataQuality(DataQualityScan scan, int threadCount) {
        DbSettings dbSettings = scan.getDbSettings();
        Long scanId = scan.getId();
        String dbType = adaptDbType(dbSettings.getDbType());
        String server = adaptServer(dbType, dbSettings.getServer(), dbSettings.getDatabase());
        String schema = adaptDataBaseSchema(dbSettings.getDatabase(), dbSettings.getSchema());
        String dqdCmd = format("dataQualityCheck(\"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", %d, %d)",
                dbType,
                server,
                dbSettings.getPort(),
                schema,
                dbSettings.getUser(),
                dbSettings.getPassword(),
                scanId,
                threadCount
        );
        REXP runResponse = rConnection.parseAndEval(toTryCmd(dqdCmd));
        if (runResponse.inherits("try-error")) {
            throw new RException(runResponse.asString());
        }

        return runResponse.asString();
    }

    @SneakyThrows
    public Integer getRServerPid() {
        String cmd = "Sys.getpid()";
        return rConnection.eval(cmd).asInteger();
    }

    @SneakyThrows
    public void abort(int pid) {
        rConnection.eval("tools::pskill("+ pid + ")");
        rConnection.eval("tools::pskill("+ pid + ", tools::SIGKILL)");

        this.close();
    }

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
