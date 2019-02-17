import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

import 'package:issue_tracker/utilities.dart';

class ErrorMessageSection extends StatelessWidget {
  ErrorMessageSection({this.errorMessage});

  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return Text(
      errorMessage,
      style: TextStyle(
        color: Colors.red,
        fontSize: 15.0,
      ),
      softWrap: true,
    );
  }
}

class Subtitle extends StatelessWidget {
  Subtitle({this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0.0, 32.0, 0.0, 0.0),
      child: Text(
        text,
        style: Theme.of(context).textTheme.title,
      ),
    );
  }
}

class LastUpdated extends StatelessWidget {
  LastUpdated({this.lastUpdatedTimestamp});

  final Timestamp lastUpdatedTimestamp;

  @override
  Widget build(BuildContext context) {
    String lastUpdated =
        Utilities.lastReportedFormat(lastUpdatedTimestamp.toDate());

    return Text(lastUpdated);
  }
}

class Tag extends StatelessWidget {
  Tag({this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      color: Theme.of(context).accentColor,
    );
  }
}

class PlaceholderMessage extends StatelessWidget {
  PlaceholderMessage({this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 18,
          //ToDo Implement custom theme and use "color: Theme.of(context).accentTextTheme.caption.color",
          color: Colors.black54,
        ),
      ),
    );
  }
}

class LocationFormWidget extends StatefulWidget {
  LocationFormWidget({
    this.latitudeController,
    this.longitudeController,
  });

  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final LocationFormWidgetState lfws = LocationFormWidgetState();

  void reset() {
    lfws.reset();
  }

  bool includeLocation() {
    return lfws._addLocation;
  }

  @override
  State<StatefulWidget> createState() => lfws;
}

class LocationFormWidgetState extends State<LocationFormWidget> {
  bool _addLocation;
  bool _currentLocationSelected;
  StreamSubscription<Map<String, double>> _locationSubscription;
  Location _location;
  bool _permission;
  String _errorMessage;
  Map<String, double> _currentLocation;

  void _setLocation() {
    if (_currentLocation != null) {
      widget.latitudeController.text = '${_currentLocation['latitude']}';
      widget.longitudeController.text = '${_currentLocation['longitude']}';
    } else {
      widget.latitudeController.text = '';
      widget.longitudeController.text = '';
    }
  }

  void _initPlatformState() async {
    try {
      _permission = await _location.hasPermission();
    } on PlatformException {
      final res = await SimplePermissions.requestPermission(
          Permission.AccessFineLocation);
      if (res == PermissionStatus.authorized) {
        _permission = true;
      } else if (res == PermissionStatus.denied) {
        _errorMessage = 'Location Permission denied.';
      } else if (res == PermissionStatus.deniedNeverAsk) {
        _errorMessage =
            'Location Permission denied. Please enable in app settings, close this form and try again.';
      }
    }

    if (_permission) {
      _locationSubscription =
          _location.onLocationChanged().listen((Map<String, double> result) {
        _currentLocation = result;
        if (_currentLocationSelected) {
          _setLocation();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _addLocation = false;
    _currentLocationSelected = true;

    _location = Location();
    _permission = false;
    _errorMessage = null;

    _initPlatformState();
  }

  void reset() {
    setState(() {
      _addLocation = false;
      _currentLocationSelected = true;
    });
    _setLocation();
  }

  @override
  void dispose() {
    super.dispose();
    if (_locationSubscription != null) {
      _locationSubscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget _getLocationRadioListTile(String title, bool value) {
      return RadioListTile<bool>(
        title: Text(title),
        value: value,
        groupValue: _currentLocationSelected,
        onChanged: (bool value) {
          setState(() {
            _currentLocationSelected = value;
          });
          if (_currentLocationSelected) {
            _setLocation();
          }
        },
      );
    }

    Widget _locationTextFields = Row(
      children: <Widget>[
        Expanded(
          child: TextFormField(
            validator: (value) {
              value = value.trim();
              var convertedValue = double.tryParse(value);
              if (value.isEmpty) {
                return 'Please enter a latitude';
              }
              if (convertedValue == null ||
                  convertedValue < Configurations.LOWER_LATITUDE ||
                  convertedValue > Configurations.UPPER_LATITUDE) {
                return 'Invalid latitude entered';
              }
            },
            controller: widget.latitudeController,
            decoration: const InputDecoration(
              hintText: 'Latitude',
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            enabled: !_currentLocationSelected,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
        ),
        Expanded(
          child: TextFormField(
            validator: (value) {
              value = value.trim();
              var convertedValue = double.tryParse(value);
              if (value.isEmpty) {
                return 'Please enter a longitude';
              }
              if (convertedValue == null ||
                  convertedValue < Configurations.LOWER_LONGITUDE ||
                  convertedValue > Configurations.UPPER_LONGITUDE) {
                return 'Invalid longitude entered';
              }
            },
            controller: widget.longitudeController,
            decoration: const InputDecoration(
              hintText: 'Longitude',
            ),
            keyboardType:
                TextInputType.numberWithOptions(signed: true, decimal: true),
            enabled: !_currentLocationSelected,
          ),
        ),
      ],
    );

    Widget _getLocationFields() {
      if (_addLocation) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: _currentLocationSelected && !_permission
                  ? Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.red[900],
                        fontSize: 12.0,
                      ),
                      softWrap: true,
                    )
                  : Container(),
            ),
            _getLocationRadioListTile(
              'Current location',
              true,
            ),
            _getLocationRadioListTile(
              'Specify location',
              false,
            ),
            _locationTextFields,
          ],
        );
      } else {
        return Container();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Column(
        children: <Widget>[
          CheckboxListTile(
            title: const Text('Include the location of the issue'),
            value: _addLocation,
            onChanged: (bool value) {
              setState(() {
                _addLocation = value;
              });
            },
          ),
          _getLocationFields(),
        ],
      ),
    );
  }
}

class ImageSubmissionWidget extends StatefulWidget {
  ImageSubmissionWidget({
    this.limit,
  });

  final ImageSubmissionWidgetState isws = ImageSubmissionWidgetState();
  final int limit;

  void clear() {
    isws.clear();
  }

  Map<String, File> getImages() {
    return isws._imageFiles;
  }

  @override
  State<StatefulWidget> createState() => isws;
}

class ImageSubmissionWidgetState extends State<ImageSubmissionWidget> {
  final Map<String, File> _imageFiles = Map();

  void clear() {
    setState(() {
      _imageFiles.clear();
    });
  }

  void showSnackBar(String message) {
    final snackBar = SnackBar(content: Text(message));
    Scaffold.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    bool _validImage(File imageFile) {
      if (imageFile == null) {
        showSnackBar('No image selected.');
        return false;
      }

      try {
        final fileLength = imageFile.lengthSync();
        if (fileLength < Configurations.MIN_FILE_LENGTH) {
          showSnackBar('Please select a higher quality image.');
          return false;
        }
      } on Exception {
        showSnackBar('Invalid image, please try again.');
        return false;
      }

      if (_imageFiles.containsKey(imageFile.path)) {
        showSnackBar('Duplicate image selected.');
        return false;
      }

      return true;
    }

    int _getRemainingValue() {
      if (widget.limit == null) {
        return Constants.NO_LIMIT;
      } else {
        int _remaining = widget.limit;
        if (_imageFiles.isNotEmpty) {
          _remaining -= _imageFiles.length;
        }
        return _remaining;
      }
    }

    Widget _getRemainingSection() {
      int _remaining = _getRemainingValue();
      if (_remaining == Constants.NO_LIMIT) {
        return Container();
      } else {
        return Text('Remaining: $_remaining');
      }
    }

    Widget _getImageSelectionButton(
      IconData icon,
      double iconSize,
      String title,
      ImageSource source,
    ) {
      int _remaining = _getRemainingValue();

      Icon _icon;
      if (iconSize != Constants.DEFAULT_SIZE) {
        _icon = Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: iconSize,
        );
      } else {
        _icon = Icon(
          icon,
          color: Theme.of(context).primaryColor,
        );
      }

      return IconButton(
        icon: _icon,
        tooltip: title,
        onPressed: (_remaining != Constants.NO_LIMIT && _remaining <= 0)
            ? null
            : (() {
                ImagePicker.pickImage(source: source).then((File imageFile) {
                  setState(() {
                    if (_validImage(imageFile)) {
                      _imageFiles[imageFile.path] = imageFile;
                    }
                  });
                });
              }),
      );
    }

    Widget _buildImageList() {
      if (_imageFiles.isNotEmpty) {
        Column column = Column(
          children: <Widget>[],
        );
        _imageFiles.forEach((_path, _imageFile) {
          column.children.add(
            Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _path,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                      ),
                      onPressed: () {
                        setState(() {
                          _imageFiles.remove(_path);
                        });
                      },
                    )
                  ],
                ),
                Divider(),
              ],
            ),
          );
        });
        return column;
      } else {
        return Text('No images selected');
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'ATTACH IMAGES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: <Widget>[
                _getImageSelectionButton(
                  Icons.add_a_photo,
                  Constants.DEFAULT_SIZE,
                  'Take a photo',
                  ImageSource.camera,
                ),
                _getImageSelectionButton(
                  Icons.add_photo_alternate,
                  27.0,
                  'Choose image from gallery',
                  ImageSource.gallery,
                ),
              ],
            ),
          ],
        ),
        _getRemainingSection(),
        Divider(),
        _buildImageList(),
      ],
    );
  }
}
