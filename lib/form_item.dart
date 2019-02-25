part of easy_form;

typedef Widget FormItemBuilder(BuildContext context, FieldData fieldData, FormActions formActions);

class Item extends StatelessWidget {
  Item(
      {@required this.name,
      @required this.builder,
      this.parseValue,
      this.formatValue,
      this.formatOnBlur,
      this.validate});

  final String name;
  final FormItemBuilder builder;
  final ParseValueCallback parseValue;
  final FormatValueCallback formatValue;
  final FieldValidateCallback validate;
  final bool formatOnBlur;

  @override
  Widget build(BuildContext context) {
    Bloc bloc = Provider.of(context).bloc;
    Field field = bloc.registerField(name,
        parseValue: parseValue,
        formatValue: formatValue,
        formatOnBlur: formatOnBlur ?? false,
        validate: validate);

    return StreamBuilder(
      key: ValueKey("FIELD_$name"),
      stream: field.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Container(
            key: ValueKey("FIELD_${name}_EMPTY"),
          );
        return builder(context, snapshot.data, bloc.formActions);
      },
    );
  }
}
