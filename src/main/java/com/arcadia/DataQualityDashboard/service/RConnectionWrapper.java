package com.arcadia.DataQualityDashboard.service;

import com.arcadia.DataQualityDashboard.dto.DbSettings;
import lombok.AllArgsConstructor;
import lombok.SneakyThrows;
import org.rosuda.REngine.REXP;
import org.rosuda.REngine.REXPMismatchException;
import org.rosuda.REngine.REngineException;
import org.rosuda.REngine.Rserve.RConnection;

import java.util.List;

import static com.arcadia.DataQualityDashboard.service.DbTypeAdapter.adaptDbType;
import static com.arcadia.DataQualityDashboard.util.OperationSystem.isUnix;
import static java.lang.String.format;

@AllArgsConstructor
public class RConnectionWrapper {

    private final RConnection rConnection;

    @SneakyThrows({REXPMismatchException.class, REngineException.class})
    public void loadScripts(List<String> scriptsPaths) throws RException {
        for (String path : scriptsPaths) {
            String cmd = format("source('%s')", path);
            REXP runResponse = rConnection.parseAndEval(toTryCmd(cmd));
            if (runResponse.inherits("try-error")) {
                throw new RException(runResponse.asString());
            }
        }
    }

    public String checkDataQuality(DbSettings dbSettings, String userId) throws RException, DbTypeNotSupportedException {
        return checkDataQuality(dbSettings, userId, 3);
    }

    @SneakyThrows({REXPMismatchException.class, REngineException.class})
    public String checkDataQuality(DbSettings dbSettings, String userId, int threadCount) throws RException, DbTypeNotSupportedException {
        String dqdCmd = format("dataQualityCheck(\"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", %d)",
                adaptDbType(dbSettings.getDbType()),
                dbSettings.getServer(),
                dbSettings.getPort(),
                format("%s.%s", dbSettings.getDatabase(), dbSettings.getSchema()),
                dbSettings.getUser(),
                dbSettings.getPassword(),
                userId,
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
    public void cancel(int pid) {
        rConnection.eval("tools::pskill("+ pid + ")");
        rConnection.eval("tools::pskill("+ pid + ", tools::SIGKILL)");

        this.close();
    }

    @SneakyThrows
    public void close() {
        if (isUnix()) {
            this.rConnection.close();
        } else {
            this.rConnection.shutdown();
        }
    }

    private String toTryCmd(String cmd) {
        return "try(eval(" + cmd + "),silent=TRUE)";
    }
}
