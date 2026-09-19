package com.taskmanager.task.controller;

import com.taskmanager.auth.security.UserPrincipal;
import com.taskmanager.common.response.PageResponse;
import com.taskmanager.task.dto.TaskRequest;
import com.taskmanager.task.dto.TaskResponse;
import com.taskmanager.task.entity.TaskStatus;
import com.taskmanager.task.service.TaskService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/tasks")
@Tag(name = "Tasks", description = "Authenticated CRUD, search and filtering of tasks")
public class TaskController {

    private final TaskService taskService;

    public TaskController(TaskService taskService) {
        this.taskService = taskService;
    }

    @GetMapping
    @Operation(summary = "List the caller's tasks with optional status filter and text search")
    public PageResponse<TaskResponse> getTasks(@AuthenticationPrincipal UserPrincipal principal,
                                               @RequestParam(required = false) TaskStatus status,
                                               @RequestParam(required = false) String search,
                                               @RequestParam(defaultValue = "0") int page,
                                               @RequestParam(defaultValue = "20") int size) {
        return taskService.getTasks(principal.id(), status, search, page, size);
    }

    @PostMapping
    @Operation(summary = "Create a task")
    public ResponseEntity<TaskResponse> createTask(@AuthenticationPrincipal UserPrincipal principal,
                                                   @Valid @RequestBody TaskRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(taskService.createTask(principal.id(), request));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update one of the caller's tasks")
    public TaskResponse updateTask(@AuthenticationPrincipal UserPrincipal principal,
                                   @PathVariable Long id,
                                   @Valid @RequestBody TaskRequest request) {
        return taskService.updateTask(principal.id(), id, request);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete one of the caller's tasks")
    public ResponseEntity<Void> deleteTask(@AuthenticationPrincipal UserPrincipal principal,
                                           @PathVariable Long id) {
        taskService.deleteTask(principal.id(), id);
        return ResponseEntity.noContent().build();
    }
}