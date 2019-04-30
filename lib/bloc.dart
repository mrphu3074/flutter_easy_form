part of easy_form;

class Bloc {
	Map<String, Field> _fields = Map();
	Map<String, dynamic> _initialValues = Map();
	BehaviorSubject<Map<String, dynamic>> _values;
	BehaviorSubject<Map<String, String>> _errors;
	BehaviorSubject<Map<String, bool>> _touched;
	BehaviorSubject<bool> _valid;
	BehaviorSubject<int> _submitCount = BehaviorSubject.seeded(0);
	bool validateOnChange = false;
	List<StreamSubscription> _subscriptions = [];
	ValidateFormCallback validateForm;
	OnSubmitCallback submitForm;
	Map<String, Observable> _subscriptionCached;

	Bloc({Map<String, dynamic> initialValues,
		this.validateOnChange = false,
		this.validateForm,
		this.submitForm}) {
		_initialValues = Map.from(flattenMap(initialValues));
		_values = new BehaviorSubject.seeded(_initialValues ?? Map());
		_errors = new BehaviorSubject.seeded(Map());
		_touched = new BehaviorSubject.seeded(Map());
		_valid = new BehaviorSubject<bool>.seeded(false);
		_fields = Map();
		_subscriptionCached = Map();
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

	Observable<Map<String, dynamic>> get values$ {
		return _values.asBroadcastStream().shareReplay(maxSize: 1);
	}

	Map<String, dynamic> get values {
		return _values.value;
	}

	set values(Map<String, dynamic> values) {
		_values.add(values);
	}

	Observable<Map<String, String>> get errors$ {
		return _errors.asBroadcastStream().shareReplay(maxSize: 1);
	}

	Map<String, String> get errors {
		return _errors.value;
	}

	set errors(Map<String, String> err) {
		_errors.add(err);
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
		return values$
				.map((nextValues) => !deepMapEquals(_initialValues, nextValues))
				.distinct((a, b) => a != b)
				.asBroadcastStream()
				.shareReplay(maxSize: 1);
	}

	bool get dirty {
		return !deepMapEquals(_initialValues, values);
	}

	Observable<int> get submitCount$ {
		return _submitCount.asBroadcastStream().shareReplay(maxSize: 1);
	}

	get submitCount {
		return _submitCount.value;
	}

	set submitCount(int count) {
		_submitCount.add(count);
	}

	FormData get formData {
		return FormData(
				values: values,
				values$: values$,
				errors: errors,
				errors$: errors$,
				touched: touched,
				touched$: touched$,
				valid: valid,
				valid$: valid$,
				dirty: dirty,
				dirty$: dirty$,
				submitCount: submitCount,
				submitCount$: submitCount$);
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
				focusField: focusField);
	}

	Observable<T> getFieldValue<T>(Observable<Map<String, T>> stream, String name) {
		return stream.map((v) => v[name]).distinct((a, b) => a == b);
	}

	Field registerField(String name, {
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
			};
			_fields[name] = Field(name,
					value$: getFieldValue(values$, name),
					error$: getFieldValue<String>(errors$, name),
					touched$: getFieldValue<bool>(touched$, name),
					parseValue: parseValue,
					formatOnBlur: formatOnBlur,
					formatValue: formatValue,
					onChanged: onChanged,
					setValue: onChanged,
					validate: validate
		);

			_subscriptions.add(
					_fields[name].value$.listen((_) {
						this.setFieldTouched(name);
					})
			);
		}
		return _fields[name];
	}

	Field getField(String name) {
		if (_fields.containsKey(name)) return _fields[name];
		return null;
	}

	Observable<FormData> createSubscription(
			{bool values, bool errors, bool touched, bool valid, bool dirty, bool submitCount}) {
		String key =
		[values, errors, touched, valid, dirty, submitCount].map((v) => v == true ? 1 : 0).join("");
		if (!_subscriptionCached.containsKey(key)) {
			Observable<Map<String, dynamic>> valueSource = values ? values$ : Observable.just(Map());
			Observable errorSource = errors == true ? errors$ : Observable.just(Map());
			Observable touchedSource = touched == true ? touched$ : Observable.just(Map());
			Observable validSource = valid == true ? valid$ : Observable.just(false);
			Observable dirtSource = dirty == true ? dirty$ : Observable.just(false);
			Observable submitCountSource = submitCount == true ? submitCount$ : Observable.just(0);
			_subscriptionCached.putIfAbsent(
					key,
							() =>
							Observable.combineLatest6(
									valueSource,
									errorSource,
									touchedSource,
									validSource,
									dirtSource,
									submitCountSource,
											(nextValues, nextErrors, nextTouched, nextValid, dirty, submitCount) {
										return FormData(
											values: Map.from(buildNestedMap(nextValues)),
											errors: Map.from(nextErrors),
											touched: Map.from(nextTouched),
											valid: nextValid,
											dirty: dirty,
											submitCount: submitCount,
										);
									}).asBroadcastStream().shareReplay(maxSize: 1));
		}
		return _subscriptionCached[key];
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
		Map<String, dynamic> nextValues = Map.from(values)
			..[name] = value;
		values = nextValues;
		if (value is String) {
			_fields[name].textController.text = value;
		}
	}

	void setFieldError(String name, String errorMsg) {
		Map<String, String> nextErrors = Map.from(errors)
			..[name] = errorMsg;
		errors = nextErrors;
	}

	void setFieldTouched(String name) {
		Map<String, bool> nextTouched = Map.from(touched)
			..[name] = true;
		touched = nextTouched;
	}

	void focusField(BuildContext context, String fieldName) {
		if (_fields.containsKey(fieldName)) {
			FocusScope.of(context).requestFocus(_fields[fieldName].focusNode);
		}
	}

	reset() {
		_submitCount.add(0);
		_values.add(Map.from(_initialValues));
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
			kErrors = Map.from(validateForm(buildNestedMap<String, dynamic>(values)));
		}
		_fields.values.forEach((field) {
			if (field.validate != null) {
				kErrors[field.name] = field.validate(values[field.name]);
			}
		});
		kErrors.removeWhere((key, value) => value == null);
		errors = kErrors;
		return kErrors.keys.length == 0;
	}

	void submit() {
		_fields.values.forEach((field) {
			if (field.focusNode.hasFocus) {
				field.focusNode.unfocus();
			}
		});
		if (submitForm != null) {
			submitForm(values, formActions);
			submitCount = submitCount + 1;
		}
	}
}
