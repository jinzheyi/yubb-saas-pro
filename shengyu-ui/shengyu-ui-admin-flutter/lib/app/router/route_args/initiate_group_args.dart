class InitiateGroupArgs {
  const InitiateGroupArgs.create()
    : mode = InitiateGroupMode.create,
      groupId = null,
      groupName = null,
      selectionLimit = 500;

  const InitiateGroupArgs.add({
    required this.groupId,
    this.groupName,
    this.selectionLimit = 500,
  }) : mode = InitiateGroupMode.add;

  final InitiateGroupMode mode;
  final String? groupId;
  final String? groupName;
  final int selectionLimit;

  bool get isAddMode => mode == InitiateGroupMode.add;
}

enum InitiateGroupMode { create, add }
