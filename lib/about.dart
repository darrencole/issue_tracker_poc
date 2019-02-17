import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';

class About extends StatelessWidget {
  Widget _getDetailLine(Widget content) {
    return Container(
      padding: EdgeInsets.only(top: 8.0),
      child: content,
    );
  }

  Widget _getAppSection() {
    return FutureBuilder(
      future: PackageInfo.fromPlatform(),
      builder: (_, AsyncSnapshot<PackageInfo> snapshot) {
        if (snapshot.hasData) {
          PackageInfo _packageInfo = snapshot.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _getDetailLine(
                Text(
                  _packageInfo.appName,
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
              _getDetailLine(
                Text('Version: ${_packageInfo.version}'),
              ),
              // TODO: update before release.
              _getDetailLine(
                Text('Last Updated: 02/11/2018'),
              ),
            ],
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
      ),
      body: Container(
        padding: const EdgeInsets.all(32.0),
        child: ListView(
          children: <Widget>[
            _getAppSection(),
          ],
        ),
      ),
    );
  }
}
