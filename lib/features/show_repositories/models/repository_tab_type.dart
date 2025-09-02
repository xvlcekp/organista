enum RepositoryTabType {
  global(0),
  personal(1);

  final int value;
  const RepositoryTabType(this.value);

  static RepositoryTabType fromIndex(int index) {
    return RepositoryTabType.values.firstWhere(
      (type) => type.index == index,
      orElse: () => RepositoryTabType.global,
    );
  }

  bool get isGlobal => this == RepositoryTabType.global;
  bool get isPersonal => this == RepositoryTabType.personal;
}
