part of easy_form;

typedef Widget SubscriptionBuilder(BuildContext context, FormData formState);

class Subscription extends StatelessWidget {
  final SubscriptionBuilder builder;
  final bool values;
  final bool errors;
  final bool touched;
  final bool valid;

  Subscription(
      {this.builder,
      this.values = false,
      this.errors = false,
      this.touched = false,
      this.valid = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Provider.of(context)
          .bloc
          .createSubscription(values: values, errors: errors, touched: touched, valid: valid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        return builder(context, snapshot.data);
      },
    );
  }
}
