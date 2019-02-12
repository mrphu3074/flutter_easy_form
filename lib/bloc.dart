part of easy_form;

class Bloc {
  Map<String, Field> _fields = Map();
  Map<String, dynamic> _prevValues = Map();
  BehaviorSubject<Map<String, dynamic>> _values = BehaviorSubject();
  BehaviorSubject<Map<String, String>> _errors = BehaviorSubject();
  BehaviorSubject<Map<String, bool>> _touched = BehaviorSubject();
  BehaviorSubject<bool> _valid = BehaviorSubject(seedValue: false);
  BehaviorSubject<bool> _dirty = BehaviorSubject(seedValue: false);
  bool validateOnChange = false;
  List<StreamSubscription> _subscriptions = [];
  ValidateFormCallback validateForm;
  OnSubmitCallback submitForm;

  Observable<Map<String, dynamic>> get values$ {
    return _values.asBroadcastStream().shareReplay(maxSize: 1);
  }

  Map<String, dynamic> get values {
    return _values.value;
  }

  set values(Map<String, dynamic> values) {
    _values.add(values);
    if (!dirty) dirty = true;
  }

  Observable<Map<String, String>> get errors$ {
    return _errors.asBroadcastStream().shareReplay(maxSize: 1);
  }

  Map<String, String> get errors {
    return _errors.value;
  }

  set errors(Map<String, String> err) {
    _errors.add(err);
    if (!dirty) dirty = true;
  }

  Observable get touched$ {
    return _touched.asBroadcastStream().shareReplay(maxSize: 1);
  }

  get touched {
    return _touched.value;
  }

  set touched(Map<String, bool> touched) {
    _touched.add(touched);
  }

  Observable<bool> get valid$ {
    return _valid.distinct((a, b) => a == b).asBroadcastStream().shareReplay(maxSize: 1);
  }

  bool get valid {
    return _valid.value;
  }

  set valid(bool value) {
    _valid.add(value);
  }

  Observable<bool> get dirty$ {
    return _dirty.distinct((a, b) => a == b).asBroadcastStream().shareReplay(maxSize: 1);
  }

  bool get dirty {
    return _dirty.value;
  }

  set dirty(bool value) {
    _dirty.add(value);
  }

  FormData get state {
    return FormData(values: values, errors: errors, touched: touched, valid: valid);
  }

  Observable<FormData> get state$ {
    return Observable.combineLatest4(values$, errors$, touched$, valid$,
        (values, errors, touched, valid) {
      return FormData(values: values, errors: errors, touched: touched, valid: valid);
    }).asBroadcastStream().shareReplay(maxSize: 1);
  }

  Bloc(
      {Map<String, dynamic> initialValues,
      this.validateOnChange = false,
      this.validateForm,
      this.submitForm}) {
    _prevValues = Map.from(initialValues);
    _values = new BehaviorSubject(seedValue: initialValues ?? Map());
    _errors = new BehaviorSubject(seedValue: Map());
    _touched = new BehaviorSubject(seedValue: Map());
    _valid = new BehaviorSubject<bool>(seedValue: false);
    _fields = Map();
    _subscriptions = [];

    // Validate on value changed
    _subscriptions.add(_values.skip(1).listen((_) {
      if (this.validateOnChange && dirty) {
        this.validate();
      }
    }));

    _subscriptions.add(_errors.skip(1).listen((_) {
      if (dirty) {
        valid = errors.keys.length == 0;
      }
    }));
  }

  Observable<T> getFieldValue<T>(Observable<Map<String, T>> stream, String name) {
    return stream.map((v) => v[name]).distinct((a, b) => a == b);
  }

  Field registerField(
    String name, {
    ParseValueCallback parseValue,
    FormatValueCallback formatValue,
    bool formatOnBlur,
    FieldValidateCallback validate,
  }) {
    if (!_fields.containsKey(name)) {
      ValueChanged onChanged = (value) {
        Map<String, dynamic> nextValues = Map.from(values);
        nextValues[name] = formatValue != null ? formatValue(value) : value;
        values = nextValues;
        if (touched[name] != true) {
          Map<String, bool> nextTouched = Map.from(touched);
          nextTouched[name] = true;
          touched = nextTouched;
        }
        if (!dirty) {
          dirty = true;
        }
      };
      _fields[name] = Field(name,
          value$: getFieldValue(values$, name),
          error$: getFieldValue<String>(errors$, name),
          touched$: getFieldValue<bool>(touched$, name),
          parseValue: parseValue,
          formatOnBlur: formatOnBlur,
          formatValue: formatValue,
          onChanged: onChanged,
          validate: validate);
    }
    return _fields[name];
  }

  Field getField(String name) {
    if (_fields.containsKey(name)) return _fields[name];
    return null;
  }

  Observable<FormData> createSubscription({bool values, bool errors, bool touched, bool valid}) {
    Observable<Map<String, dynamic>> valueSource = values ? values$ : Observable.just(Map());
    Observable errorSource = errors ? values$ : Observable.just(Map());
    Observable touchedSource = touched ? touched$ : Observable.just(Map());
    Observable validSource = valid ? valid$ : Observable.just(false);
    return Observable.combineLatest4(valueSource, errorSource, touchedSource, validSource,
        (Map nextValues, nextErrors, nextTouched, nextValid) {
      return FormData(
          values: Map.from(nextValues),
          errors: Map.from(nextErrors),
          touched: Map.from(nextTouched),
          valid: nextValid);
    });
  }

  /// FORM ACTIONS
  dispose() {
    _values.close();
    _errors.close();
    _touched.close();
    _valid.close();
    _fields.values.forEach((field) {
      field.textController.dispose();
      field.focusNode.dispose();
    });
    _subscriptions.forEach((sub) => sub.cancel());
  }

  void setFieldValue(String name, value) {
    Map<String, dynamic> nextValues = Map.from(values)..[name] = value;
    values = nextValues;
    if (value is String) {
      _fields[name].textController.text = value;
    }
  }

  void setFieldError(String name, String errorMsg) {
    Map<String, String> nextErrors = Map.from(errors)..[name] = errorMsg;
    errors = nextErrors;
  }

  void setFieldTouched(String name) {
    Map<String, bool> nextTouched = Map.from(touched)..[name] = true;
    touched = nextTouched;
  }

  reset() {
    _dirty.add(false);
    _values.add(Map.from(_prevValues));
    _errors.add(Map());
    _touched.add(Map());
    valid = false;
    _fields.values.forEach((f) {
      if (f.focusNode.hasFocus) {
        f.focusNode.unfocus();
      }
      if (values[f.name] is String) {
        f.textController.text = values[f.name];
      }
    });
  }

  bool validate() {
    Map<String, String> kErrors = Map();
    if (validateForm != null) {
      kErrors = Map.from(validateForm(values));
    }
    _fields.values.forEach((field) {
      if (field.validate != null) {
        kErrors[field.name] = field.validate(values[field.name]);
      }
    });
    kErrors.removeWhere((key, value) => value == null);
    errors = kErrors;
    return kErrors.keys.length > 0;
  }

  FormActions get formActions {
    return new FormActions(
      setFieldValue: setFieldValue,
      setFieldError: setFieldError,
      setFieldTouched: setFieldTouched,
      setValues: (values) => this.values = values,
      setErrors: (errors) => this.errors = errors,
      setTouched: (touched) => this.touched = touched,
      resetForm: reset,
      submitForm: submit,
      validateForm: validate,
    );
  }

  void submit() {
    if (submitForm != null) {
      submitForm(values, formActions);
    }
  }
}
