part of easy_form;

typedef String FieldValidateCallback(value);
typedef void ValidateFieldCallback(String field);
typedef Map ValidateFormCallback(Map<String, dynamic> values);
typedef OnSubmitCallback(Map<String, dynamic> values, FormActions actions);
typedef dynamic ParseValueCallback(value);
typedef dynamic FormatValueCallback(value);
typedef void SetValuesAction(Map<String, dynamic> fields);
typedef void SetFieldValueAction(String field, value);
typedef void SetErrorsAction(Map<String, String> fields);
typedef void SetFieldErrorAction(String field, String error);
typedef void SetTouchedAction(Map<String, bool> fields);
typedef void SetFieldTouchedAction(String field);
typedef void SetSubmittingAction(bool isSubmitting);
typedef bool ValidateAction();
typedef void SubmitFormAction();
typedef void FocusAction(BuildContext context, String fieldName);

@immutable
class FormData {
  final Map<String, dynamic> values;
  final Observable<Map<String, dynamic>> values$;
  final Map<String, String> errors;
  final Observable<Map<String, String>> errors$;
  final Map<String, bool> touched;
  final Observable<Map<String, bool>> touched$;
  final bool valid;
  final Observable<bool> valid$;
  final bool dirty;
  final Observable<bool> dirty$;
  final int submitCount;
  final Observable<int> submitCount$;

  FormData(
      {this.values,
      this.values$,
      this.errors,
      this.errors$,
      this.touched,
      this.touched$,
      this.valid,
      this.valid$,
      this.dirty,
      this.dirty$,
      this.submitCount,
      this.submitCount$});
}

@immutable
class FormActions {
  final SetValuesAction setValues;
  final SetErrorsAction setErrors;
  final SetTouchedAction setTouched;
  final SetFieldValueAction setFieldValue;
  final SetFieldErrorAction setFieldError;
  final SetFieldTouchedAction setFieldTouched;
  final SetSubmittingAction setSubmitting;
  final SubmitFormAction submitForm;
  final ValidateAction validateForm;
  final ValidateFieldCallback validateField;
  final VoidCallback resetForm;
  final FocusAction focusField;

  FormActions(
      {this.setValues,
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
      this.focusField});
}

@immutable
class FieldData {
  final String name;
  final dynamic value;
  final String error;
  final bool touched;
  final TextEditingController textController;
  final FocusNode focusNode;
  final ValueChanged onChanged;

  FieldData(this.name,
      {this.value, this.error, this.touched, this.textController, this.focusNode, this.onChanged});
}

class Field {
  String name;
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

  Observable<FieldData> get stream {
    return Observable.combineLatest3(value$, error$, touched$, (value, error, touched) {
      return FieldData(name,
          value: parseValue != null ? parseValue(value) : value,
          error: error,
          touched: touched,
          textController: textController,
          focusNode: focusNode,
          onChanged: onChanged);
    })
        .distinct((a, b) {
          return a.value == b.value && a.error == b.error && a.touched == b.touched;
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
    this.focusNode ??= FocusNode();
    this.textController ??= TextEditingController();

    value$.first.then((value) {
      if (value is String) {
        this.textController
          ..text = value
          ..addListener(() {
            this.onChanged(this.textController.text);
          });
      }
    });
  }
}
