extension StringIsNumeric on String {
  bool isNumeric() {
    bool b = true;
    try {
        double.parse(this);
    } catch (e) {
      b = false;
    } 
    return b;
  }
}
