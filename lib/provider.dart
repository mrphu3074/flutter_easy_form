part of easy_form;

class Provider extends InheritedWidget {
  Provider({this.bloc, Key key, Widget child}) : super(key: key, child: child);

  final Bloc bloc;

  static Provider of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(Provider) as Provider;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return false;
  }
}
