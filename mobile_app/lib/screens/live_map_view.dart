import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../theme/colors.dart';

class LiveMapView extends StatefulWidget {
  final LatLng pickup;
  final LatLng? destination;

  const LiveMapView({
    super.key,
    required this.pickup,
    this.destination,
  });

  @override
  State<LiveMapView> createState() => _LiveMapViewState();
}

class _LiveMapViewState extends State<LiveMapView> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  // Default to IIUM Gombak if coordinates are missing/loading
  static const CameraPosition _kDefault = CameraPosition(
    target: LatLng(3.2535, 101.7346),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _updateMap();
  }

  @override
  void didUpdateWidget(covariant LiveMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickup != widget.pickup ||
        oldWidget.destination != widget.destination) {
      _updateMap();
    }
  }

  void _updateMap() {
    setState(() {
      _markers = _createMarkers();
    });
    _fetchRoute();
    _fitBounds();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _kDefault,
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
        _fitBounds();
      },
    );
  }

  Set<Marker> _createMarkers() {
    final markers = <Marker>{};

    // Pickup Marker (Green)
    markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: widget.pickup,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: "Pickup"),
    ));

    // Destination Marker (Red)
    if (widget.destination != null) {
      markers.add(Marker(
        markerId: const MarkerId('dest'),
        position: widget.destination!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: "Destination"),
      ));
    }

    return markers;
  }

  Future<void> _fetchRoute() async {
    if (widget.destination == null) {
      setState(() => _polylines = {});
      return;
    }

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null) return;

    final polylinePoints = PolylinePoints();
    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: apiKey,
        request: PolylineRequest(
          origin: PointLatLng(widget.pickup.latitude, widget.pickup.longitude),
          destination: PointLatLng(
              widget.destination!.latitude, widget.destination!.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: result.points
                  .map((point) => LatLng(point.latitude, point.longitude))
                  .toList(),
              color: UColors.teal,
              width: 5,
            ),
          };
        });
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
    }
  }

  Future<void> _fitBounds() async {
    if (widget.destination == null) return;

    final controller = await _controller.future;
    LatLngBounds bounds;

    final p1 = widget.pickup;
    final p2 = widget.destination!;

    bounds = LatLngBounds(
      southwest: LatLng(
        p1.latitude < p2.latitude ? p1.latitude : p2.latitude,
        p1.longitude < p2.longitude ? p1.longitude : p2.longitude,
      ),
      northeast: LatLng(
        p1.latitude > p2.latitude ? p1.latitude : p2.latitude,
        p1.longitude > p2.longitude ? p1.longitude : p2.longitude,
      ),
    );

    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80.0));
  }
}
