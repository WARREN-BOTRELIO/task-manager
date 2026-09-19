package com.taskmanager.task.dto;

import com.taskmanager.task.entity.TaskStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record TaskRequest(
        @NotBlank(message = "Task title is required")
        @Size(max = 120, message = "Task title must not exceed 120 characters")
        String title,

        @Size(max = 1000, message = "Task description must not exceed 1000 characters")
        String description,

        @NotNull(message = "Task status is required")
        TaskStatus status
) {
}