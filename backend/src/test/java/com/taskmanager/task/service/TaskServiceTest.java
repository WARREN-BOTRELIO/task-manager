package com.taskmanager.task.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

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
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;

class TaskServiceTest {

    private final TaskRepository taskRepository = mock(TaskRepository.class);
    private final UserRepository userRepository = mock(UserRepository.class);

    private TaskService taskService;

    @BeforeEach
    void setUp() {
        taskService = new TaskService(taskRepository, userRepository, new TaskMapper());
    }

    @Test
    void createTaskFetchesOwnerAndSaves() {
        User owner = new User("user@example.com", "hashed");
        when(userRepository.findById(1L)).thenReturn(Optional.of(owner));
        when(taskRepository.save(any(Task.class))).thenAnswer(inv -> inv.getArgument(0));

        TaskResponse response = taskService.createTask(1L,
                new TaskRequest("  Standup  ", "Prepare agenda", TaskStatus.TODO));

        assertThat(response.title()).isEqualTo("Standup");
        verify(userRepository).findById(1L);
        verify(taskRepository).save(any(Task.class));
    }

    @Test
    void createTaskRejectsUnknownOwner() {
        when(userRepository.findById(1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> taskService.createTask(1L,
                new TaskRequest("Title", null, TaskStatus.TODO)))
                .isInstanceOf(ResourceNotFoundException.class);
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void updateTaskOnlyAppliesWhenTaskBelongsToUser() {
        Task task = new Task("Old", null, TaskStatus.TODO, new User("owner@example.com", "x"));
        when(taskRepository.findByIdAndUserId(5L, 1L)).thenReturn(Optional.of(task));

        TaskResponse response = taskService.updateTask(1L, 5L,
                new TaskRequest("New title", "Updated", TaskStatus.DONE));

        assertThat(response.title()).isEqualTo("New title");
        assertThat(response.status()).isEqualTo(TaskStatus.DONE);
        assertThat(response.description()).isEqualTo("Updated");
    }

    @Test
    void updateTaskThrows404ForForeignOrMissingTask() {
        when(taskRepository.findByIdAndUserId(5L, 1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> taskService.updateTask(1L, 5L,
                new TaskRequest("Title", null, TaskStatus.TODO)))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void deleteTaskRemovesOwnedTask() {
        Task task = new Task("Title", null, TaskStatus.TODO, new User("owner@example.com", "x"));
        when(taskRepository.findByIdAndUserId(5L, 1L)).thenReturn(Optional.of(task));

        taskService.deleteTask(1L, 5L);

        verify(taskRepository).delete(task);
    }

    @Test
    void deleteTaskRejectsForeignOrMissingTask() {
        when(taskRepository.findByIdAndUserId(5L, 1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> taskService.deleteTask(1L, 5L))
                .isInstanceOf(ResourceNotFoundException.class);
        verify(taskRepository, never()).delete(any(Task.class));
    }

    @Test
    void getTasksDelegatesFiltersAndWrapsPage() {
        User owner = new User("user@example.com", "hashed");
        Task task = new Task("Meeting", "Plan the sprint", TaskStatus.TODO, owner);
        Page<Task> page = new PageImpl<>(List.of(task));

        when(taskRepository.findByUserId(eq(1L), eq(TaskStatus.TODO), eq("meeting"), any(Pageable.class)))
                .thenReturn(page);

        PageResponse<TaskResponse> result =
                taskService.getTasks(1L, TaskStatus.TODO, "  meeting ", 0, 20);

        assertThat(result.content()).hasSize(1);
        assertThat(result.content().get(0).title()).isEqualTo("Meeting");
        assertThat(result.page()).isZero();
    }

    @Test
    void getTasksClampsSizeToASafeRange() {
        Page<Task> empty = new PageImpl<>(List.of());
        when(taskRepository.findByUserId(eq(9L), any(), any(), any(Pageable.class))).thenReturn(empty);

        taskService.getTasks(9L, null, "   ", 0, 500);

        org.mockito.ArgumentCaptor<Pageable> captor =
                org.mockito.ArgumentCaptor.forClass(Pageable.class);
        verify(taskRepository).findByUserId(eq(9L), eq(null), eq(null), captor.capture());
        assertThat(captor.getValue().getPageSize()).isEqualTo(100);
    }
}