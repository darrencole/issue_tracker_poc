import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

class NoticeMap extends StatelessWidget {
  NoticeMap({
    this.noticeId,
  });

  final String noticeId;
  final String _urlTemplate =
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  final List<String> _subdomains = ['a', 'b', 'c'];

  List<Marker> _getMarkers(GeoPoint location) {
    return <Marker>[
      Marker(
        width: 80.0,
        height: 80.0,
        point: LatLng(location.latitude, location.longitude),
        builder: (ctx) => Container(
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40.0,
              ),
            ),
      ),
    ];
  }

  Widget _getCard(String text) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 17.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _getMap(DocumentSnapshot noticeSnapshot) {
    GeoPoint location = noticeSnapshot['location'];
    var markers = _getMarkers(location);
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Column(
          children: [
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: LatLng(location.latitude, location.longitude),
                  zoom: 15.0,
                ),
                layers: [
                  TileLayerOptions(
                      urlTemplate: _urlTemplate, subdomains: _subdomains),
                  MarkerLayerOptions(markers: markers),
                ],
              ),
            ),
          ],
        ),
        _getCard(noticeSnapshot['subject']),
      ],
    );
  }

  Widget _getBody() {
    return StreamBuilder(
        stream: Firestore.instance
            .collection('notices')
            .document('$noticeId')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(
              child: CircularProgressIndicator(),
            );
          DocumentSnapshot noticeSnapshot = snapshot.data;
          return _getMap(noticeSnapshot);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location'),
      ),
      body: _getBody(),
    );
  }
}
