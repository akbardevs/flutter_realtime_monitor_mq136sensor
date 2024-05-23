import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  return runApp(_ChartApp());
}

class _ChartApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
      home: _MyHomePage(),
    );
  }
}

class _MyHomePage extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  _MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<_MyHomePage> {
  List<_SensorData> data = [];
  late Timer timer;
  bool isLoading = true; // Add a loading state indicator

  Future<void> fetchDataFromAPI() async {
    var response = await http.get(Uri.parse('http://103.151.20.168:3302/data'));
    if (response.statusCode == 200) {
      List<dynamic> jsonData = jsonDecode(response.body);
      List<_SensorData> fetchedData =
          jsonData.map((item) => _SensorData.fromJson(item)).toList();
      setState(() {
        data = fetchedData;
        isLoading = false; // Set loading to false after data is fetched
      });
    } else {
      print('Failed to load data');
      setState(() {
        isLoading = false; // Also set loading to false if data fails to load
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDataFromAPI();
    Timer.periodic(const Duration(seconds: 5), (timer) => fetchDataFromAPI());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime Monitor Sensor'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator()) // Show loading spinner
          : SfCartesianChart(
              primaryXAxis: const CategoryAxis(),
              title: const ChartTitle(text: 'Real-time Data'),
              legend: const Legend(isVisible: true),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <LineSeries<_SensorData, String>>[
                LineSeries<_SensorData, String>(
                    dataSource: data,
                    xValueMapper: (_SensorData dd, _) => dd.timestamp,
                    yValueMapper: (_SensorData dd, _) => dd.value,
                    name: 'Sensor MQ136',
                    dataLabelSettings: const DataLabelSettings(isVisible: true))
              ],
            ),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}

class _SensorData {
  final String timestamp;
  final double value;

  _SensorData(this.timestamp, this.value);

  factory _SensorData.fromJson(Map<String, dynamic> json) {
    return _SensorData(
      json['timestamp']
          as String, // Assuming the timestamp is in a format you can use directly
      (json['value'] as num).toDouble(),
    );
  }
}
