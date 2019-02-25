part of easy_form;

typedef Widget SubscriptionBuilder(BuildContext context, FormData formState, FormActions actions);

class Subscription extends StatelessWidget {
  final SubscriptionBuilder builder;
  final bool values;
  final bool errors;
  final bool touched;
  final bool valid;
  final bool dirty;
  final bool submitCount;

  Subscription(
      {
        this.builder,
      this.values = false,
      this.errors = false,
      this.touched = false,
      this.valid = false,
      this.dirty = false,
      this.submitCount = false
      });

  @override
  Widget build(BuildContext context) {
    Bloc bloc = Provider.of(context).bloc;
    return StreamBuilder(
      stream: bloc.createSubscription(
          values: values,
          errors: errors,
          touched: touched,
          valid: valid,
          dirty: dirty,
          submitCount: submitCount),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        return builder(context, snapshot.data, bloc.formActions);
      },
    );
  }
}
