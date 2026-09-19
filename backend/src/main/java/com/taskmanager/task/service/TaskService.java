package com.taskmanager.task.service;

import com.taskmanager.common.exception.ResourceNotFoundException;
import com.taskmanager.common.response.PageResponse;
import com.taskmanager.task.dto.TaskRequest;
import com.taskmanager.task.dto.TaskResponse;
import com.taskmanager.task.entity.Task;
import com.taskmanager.task.entity.TaskStatus;
import com.taskmanager.task.mapper.TaskMapper;
import com.taskmanager.task.repository.TaskRepository;
import com.taskmanager.user.entity.User;
import com.taskmanager.user.repository.UserRepository;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class TaskService {

    private final TaskRepository taskRepository;
    private final UserRepository userRepository;
    private final TaskMapper taskMapper;

    public TaskService(TaskRepository taskRepository,
                       UserRepository userRepository,
                       TaskMapper taskMapper) {
        this.taskRepository = taskRepository;
        this.userRepository = userRepository;
        this.taskMapper = taskMapper;
    }

    /**
     * The authenticated user's identity (Long id) comes from the security
     * principal, never from a client-supplied value. Ownership is enforced by
     * scoping every query to that id.
     */
    @Transactional(readOnly = true)
    public PageResponse<TaskResponse> getTasks(Long userId,
                                               TaskStatus status,
                                               String search,
                                               int page,
                                               int size) {
        int safeSize = Math.min(Math.max(size, 1), 100);
        int safePage = Math.max(page, 0);
        Pageable pageable = PageRequest.of(safePage, safeSize, Sort.by(Sort.Direction.DESC, "createdAt"));

        String normalizedSearch = StringUtils.hasText(search) ? search.trim() : null;
        Page<Task> tasks = taskRepository.findByUserId(userId, status, normalizedSearch, pageable);
        List<TaskResponse> content = tasks.getContent().stream().map(taskMapper::toResponse).toList();

        return new PageResponse<>(content, tasks.getNumber(), tasks.getSize(),
                tasks.getTotalElements(), tasks.getTotalPages());
    }

    @Transactional
    public TaskResponse createTask(Long userId, TaskRequest request) {
        User owner = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));

        Task task = new Task(
                request.title().trim(),
                normalizeDescription(request.description()),
                request.status(),
                owner);

        Task saved = taskRepository.save(task);
        return taskMapper.toResponse(saved);
    }

    @Transactional
    public TaskResponse updateTask(Long userId, Long taskId, TaskRequest request) {
        Task task = findOwnedTask(userId, taskId);
        task.update(request.title().trim(), normalizeDescription(request.description()), request.status());
        return taskMapper.toResponse(task);
    }

    @Transactional
    public void deleteTask(Long userId, Long taskId) {
        Task task = findOwnedTask(userId, taskId);
        taskRepository.delete(task);
    }

    private Task findOwnedTask(Long userId, Long taskId) {
        return taskRepository.findByIdAndUserId(taskId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Task not found"));
    }

    private String normalizeDescription(String description) {
        return StringUtils.hasText(description) ? description.trim() : null;
    }
}