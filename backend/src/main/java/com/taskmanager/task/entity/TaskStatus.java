package com.taskmanager.task.entity;

public enum TaskStatus {

    TODO,
    IN_PROGRESS,
    DONE;

    public static boolean isValid(String value) {
        if (value == null) {
            return false;
        }
        for (TaskStatus status : values()) {
            if (status.name().equalsIgnoreCase(value)) {
                return true;
            }
        }
        return false;
    }
}