import 'package:flutter/material.dart';

import 'package:issue_tracker/utilities.dart';

class NoticeFilterWidget extends StatefulWidget {
  NoticeFilterWidget({
    this.filterMap,
  });

  final Map<String, dynamic> filterMap;
  final NoticeFilterWidgetState _nfws = NoticeFilterWidgetState();

  Map<String, dynamic> getSelected() {
    return _nfws._getSelected();
  }

  @override
  State<StatefulWidget> createState() => _nfws;
}

class NoticeFilterWidgetState extends State<NoticeFilterWidget> {
  FilterOption _option;
  String _category;
  String _severity;

  @override
  void initState() {
    super.initState();

    _category = Configurations.NOTICE_CATEGORIES[0];
    _severity = Configurations.SEVERITY_TYPES.keys.toList()[0];

    _option = widget.filterMap['option'];
    if (_option == FilterOption.none) {
      _option = FilterOption.category;
    } else if (_option == FilterOption.category) {
      _category = widget.filterMap['category'];
    } else if (_option == FilterOption.severity) {
      _severity = widget.filterMap['severity'];
    }
  }

  Map<String, dynamic> _getSelected() {
    Map<String, dynamic> _filterMap = {'option': _option};
    if (_option == FilterOption.category) {
      _filterMap['category'] = _category;
    } else if (_option == FilterOption.severity) {
      _filterMap['severity'] = _severity;
    }
    return _filterMap;
  }

  Widget _getFilterRadioListTile(String title, FilterOption currentValue) {
    return RadioListTile<FilterOption>(
      title: Text(title),
      value: currentValue,
      groupValue: _option,
      onChanged: (FilterOption value) {
        setState(() {
          _option = value;
        });
      },
    );
  }

  Widget _getFilterDropdownButton(
    List<String> items,
    String currentValue,
    Function function,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 72.0),
      child: DropdownButton(
        items: items.map((String dropDownItem) {
          return DropdownMenuItem(
            value: dropDownItem,
            child: Text(dropDownItem),
          );
        }).toList(),
        value: currentValue,
        onChanged: (String value) {
          setState(() {
            function(value);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _getFilterRadioListTile(
          'Category',
          FilterOption.category,
        ),
        _option == FilterOption.category
            ? _getFilterDropdownButton(
                Configurations.NOTICE_CATEGORIES,
                _category,
                (String value) {
                  _category = value;
                },
              )
            : Container(),
        _getFilterRadioListTile(
          'Severity',
          FilterOption.severity,
        ),
        _option == FilterOption.severity
            ? _getFilterDropdownButton(
                Configurations.SEVERITY_TYPES.keys.toList(),
                _severity,
                (String value) {
                  _severity = value;
                },
              )
            : Container(),
        _getFilterRadioListTile(
          'My subscriptions',
          FilterOption.mySubscriptions,
        ),
        _getFilterRadioListTile(
          'Reported by me',
          FilterOption.reportedByMe,
        ),
      ],
    );
  }
}
