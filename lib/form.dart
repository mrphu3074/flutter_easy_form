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
    if (!deepMapEquals(oldWidget.initialValues, widget.initialValues)) {
      setState(() {
        _bloc = new Bloc(
            initialValues: widget.initialValues,
            validateOnChange: widget.validateOnChange,
            validateForm: widget.validate,
            submitForm: widget.onSubmit);
      });
    } else {
      _bloc.validateForm = widget.validate;
      _bloc.validateOnChange = widget.validateOnChange;
      _bloc.submitForm = widget.onSubmit;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  FormData get data {
    return _bloc.formData;
  }

  FormActions get actions {
    return _bloc.formActions;
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      bloc: _bloc,
      child: widget.child,
    );
  }
}
