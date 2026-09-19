/// Task status values as defined by the backend `TaskStatus` enum
/// (`TODO`, `IN_PROGRESS`, `DONE`).
enum TaskStatus {
  todo('TODO'),
  inProgress('IN_PROGRESS'),
  done('DONE');

  const TaskStatus(this.wire);

  /// Wire value sent to / received from the REST API.
  final String wire;

  static TaskStatus fromWire(String? value) {
    for (final status in TaskStatus.values) {
      if (status.wire == value) {
        return status;
      }
    }
    throw FormatException('Unknown task status: $value');
  }

  String get label => switch (this) {
        TaskStatus.todo => 'To do',
        TaskStatus.inProgress => 'In progress',
        TaskStatus.done => 'Done',
      };
}