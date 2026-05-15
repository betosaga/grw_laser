extension StringToDoubleSafe on String {
  double toDoubleSafe() {
    if (this.trim() != "") {
      try {
        return double.parse(this);
      } catch (e) {
        print("StringToDoubleSafe Extension (${this}): ${e.toString()}");
        return 0;
      }
    } else {
      return 0;
    }
  }
}
