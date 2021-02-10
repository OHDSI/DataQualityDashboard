package com.arcadia.DataQualityDashboard.controller;

import com.arcadia.DataQualityDashboard.dto.CheckDataQualityResult;
import com.arcadia.DataQualityDashboard.dto.DbSettings;
import com.arcadia.DataQualityDashboard.service.TaskHandler;
import lombok.AllArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@AllArgsConstructor
@RestController
@RequestMapping("/api")
public class CheckDataQualityController {

    private final TaskHandler taskHandler;

    @PostMapping("/{userId}")
    public void dataQualityCheck(@RequestBody DbSettings dbSettings, @PathVariable String userId) {
        boolean result = this.taskHandler.createTask(dbSettings, userId);
        if (!result) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Data Quality Check process already exist");
        }
    }

    @GetMapping("/{userId}")
    public CheckDataQualityResult getResult(@PathVariable String userId) {
        try {
            String taskResult = taskHandler.getTaskResult(userId);
            return new CheckDataQualityResult(true, taskResult);
        } catch (Exception e) {
            return new CheckDataQualityResult(false, e.getMessage());
        }
    }

    @GetMapping("/cancel/{userId}")
    void cancel(@PathVariable String userId) {
        taskHandler.cancelTask(userId);
    }
}
