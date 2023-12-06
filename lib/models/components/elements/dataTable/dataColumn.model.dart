class ComponentDataColumnModule  {
  final String title;
  final bool? sortable;
  final String? sortKeyName;
  final bool numeric;
  final bool isDate;
  final double? minWidth;

  const ComponentDataColumnModule({required this.title, this.sortable, this.sortKeyName, this.minWidth = 0, this.numeric = false, this.isDate = false});
}