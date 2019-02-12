part of easy_form;

typedef void SetValuesCallback(Map<String, dynamic> fields);
typedef void SetFieldValueCallback(String field, value);
typedef void SetErrorCallback(Map<String, String> fields);
typedef void SetFieldErrorCallback(String field, String error);
typedef void SetTouchedCallback(Map<String, bool> fields);
typedef void SetFieldTouchedCallback(String field);
typedef String FieldValidateCallback(value);
typedef void ValidateFieldCallback(String field);
typedef Map<String, String> ValidateFormCallback(Map<String, dynamic> values);
typedef bool ValidateCallback();
typedef void SubmitFormCallback();
typedef OnSubmitCallback(Map<String, dynamic> values, FormActions actions);
typedef void SetSubmittingCallback(bool isSubmitting);
typedef dynamic ParseValueCallback(value);
typedef dynamic FormatValueCallback(value);

class FormData {
  FormData({this.values, this.errors, this.touched, this.valid});

  Map<String, dynamic> values = Map();
  Map<String, String> errors = Map();
  Map<String, bool> touched = Map();
  bool valid = false;
  bool dirty = false;
  bool submitting = false;
}

@immutable
class FormActions {
  final SetValuesCallback setValues;
  final SetErrorCallback setErrors;
  final SetTouchedCallback setTouched;
  final SetFieldValueCallback setFieldValue;
  final SetFieldErrorCallback setFieldError;
  final SetFieldTouchedCallback setFieldTouched;
  final SetSubmittingCallback setSubmitting;
  final SubmitFormCallback submitForm;
  final ValidateCallback validateForm;
  final ValidateFieldCallback validateField;
  final VoidCallback resetForm;

  FormActions({
    this.setValues,
    this.setErrors,
    this.setTouched,
    this.setFieldValue,
    this.setFieldError,
    this.setFieldTouched,
    this.setSubmitting,
    this.validateForm,
    this.validateField,
    this.submitForm,
    this.resetForm,
  });
}

class Field {
  String name;
  dynamic value;
  String error;
  bool touched;
  Observable value$;
  Observable<String> error$;
  Observable<bool> touched$;
  ParseValueCallback parseValue;
  FormatValueCallback formatValue;
  bool formatOnBlur;
  ValueChanged onChanged;
  FieldValidateCallback validate;
  TextEditingController textController;
  FocusNode focusNode;

  Observable<Field> get stream {
    return Observable.combineLatest3(value$, error$, touched$, (value, error, touched) {
      this.value = parseValue != null ? parseValue(value) : value;
      this.error = error;
      this.touched = touched;
      return this;
    })
        .distinct((a, b) {
          return a.value != b.value || a.error != b.error || a.touched != b.touched;
        })
        .asBroadcastStream()
        .shareReplay(maxSize: 1);
  }

  Field(this.name,
      {this.value$,
      this.error$,
      this.touched$,
      TextEditingController textController,
      FocusNode focusNode,
      this.parseValue,
      this.formatValue,
      this.formatOnBlur,
      this.onChanged,
      this.validate}) {
    this.focusNode = focusNode ?? FocusNode();
    this.textController = textController ?? TextEditingController();
    value$.first.then((value) {
      if (value is String) {
        this.textController.text = value;
      }
    });
  }
}
