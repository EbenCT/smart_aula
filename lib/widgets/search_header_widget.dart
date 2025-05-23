import 'package:flutter/material.dart';

class SearchHeaderWidget extends StatelessWidget {
  final String hintText;
  final Function(String) onSearchChanged;
  final Widget? additionalWidget;
  final TextEditingController? controller;
  final String? searchValue;

  const SearchHeaderWidget({
    Key? key,
    required this.hintText,
    required this.onSearchChanged,
    this.additionalWidget,
    this.controller,
    this.searchValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Widget adicional si se proporciona
          if (additionalWidget != null) ...[
            additionalWidget!,
            const SizedBox(height: 12),
          ],
          
          // Campo de búsqueda
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).iconTheme.color,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                         Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              suffixIcon: (searchValue?.isNotEmpty ?? false)
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).iconTheme.color,
                      ),
                      onPressed: () {
                        controller?.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}