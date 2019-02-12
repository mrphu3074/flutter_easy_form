part of easy_form;

class Form extends StatefulWidget {
  Form(
      {this.initialValues,
      this.validate,
      this.onSubmit,
      this.validateOnChange = false,
      this.child,
      Key key})
      : super(key: key);

  final Map<String, dynamic> initialValues;
  final ValidateFormCallback validate;
  final OnSubmitCallback onSubmit;
  final bool validateOnChange;
  final Widget child;

  @override
  FormState createState() {
    return FormState();
  }
}

class FormState extends State<Form> {
  Bloc _bloc;

  @override
  void initState() {
    super.initState();

    _bloc = new Bloc(
        initialValues: widget.initialValues,
        validateOnChange: widget.validateOnChange,
        validateForm: widget.validate,
        submitForm: widget.onSubmit);
  }

  @override
  void didUpdateWidget(Form oldWidget) {
    _bloc.validateForm = widget.validate;
    _bloc.validateOnChange = widget.validateOnChange;
    _bloc.submitForm = widget.onSubmit;
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  void focus(String fieldName) {
    Field field = _bloc.getField(fieldName);
    if (field != null) {
      FocusScope.of(context).requestFocus(field.focusNode);
    }
  }

  void reset() {
    _bloc.reset();
  }

  validate() {
    _bloc.validate();
  }

  submit() {
    _bloc.submit();
  }

  void setValues(Map<String, dynamic> values) {
    _bloc.values = values;
  }

  void setErrors(Map<String, String> errors) {
    _bloc.errors = errors;
  }

  void setFieldValue(String name, value) {
    _bloc.setFieldValue(name, value);
  }

  void setFieldError(String name, String errorMsg) {
    _bloc.setFieldError(name, errorMsg);
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      bloc: _bloc,
      child: widget.child,
    );
  }
}
