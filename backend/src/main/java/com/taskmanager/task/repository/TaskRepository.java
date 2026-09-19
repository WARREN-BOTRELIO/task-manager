package com.taskmanager.task.repository;

import com.taskmanager.task.entity.Task;
import com.taskmanager.task.entity.TaskStatus;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface TaskRepository extends JpaRepository<Task, Long> {

    @Query("""
            SELECT t
            FROM Task t
            WHERE t.user.id = :userId
              AND (:status IS NULL OR t.status = :status)
              AND (:search IS NULL
                   OR LOWER(t.title) LIKE LOWER(CONCAT('%', :search, '%'))
                   OR LOWER(COALESCE(t.description, '')) LIKE LOWER(CONCAT('%', :search, '%')))
            """)
    Page<Task> findByUserId(@Param("userId") Long userId,
                            @Param("status") TaskStatus status,
                            @Param("search") String search,
                            Pageable pageable);

    Optional<Task> findByIdAndUserId(Long id, Long userId);
}