class Validator {
  static bool isValidProgressiva(String input) {
    bool b;

    if (input.indexOf("+") == (input.length - 4) &&
        input.length == 7 &&
        input.isNotEmpty)
      b = true;
    else
      b = false;

    return b;
  }
}
