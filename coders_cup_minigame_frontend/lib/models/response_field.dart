class ResponseField {
  String fieldName;
  String fieldType;
  bool required;
  dynamic value;

  ResponseField({
    required this.fieldName,
    required this.fieldType,
    this.required = false,
    this.value,
  });
}
