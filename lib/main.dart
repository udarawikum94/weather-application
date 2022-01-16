import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_image/network.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http_package;
import 'package:geocoding/geocoding.dart';
import 'dart:io';

import 'package:intl/intl.dart';


void main() {
  runApp(const WeatherAppCw());
}

class WeatherAppCw extends StatefulWidget {
  const WeatherAppCw({Key? key}) : super(key: key);

  @override
  _WeatherAppState createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherAppCw> {
  String weatherApiUrl = 'http://api.openweathermap.org/data/2.5/';
  String appId = '&appId=4728d32120da0b34300f76e0f11eebdd';
  String iconSearchUrl = 'http://openweathermap.org/img/wn/';
  String iconPostName = '@2x.png';
  String locationQueryParam = 'q=';
  String latitudeQParam = 'lat=';
  String longitudeQParam = '&lon=';

  int temperature = 0;
  int feelsLike = 0;
  String location = 'Anuradhapura';
  String countryCode = 'LK';
  int pressure = 0;
  int humidity = 0;
  String sevenDayForcast = '{}';
  String backgroundImageName = 'clear';
  String iconName = '10d';

  bool dataFetched = false;

  String errorMessage = '';

  late Position currentPosition;
  late String positionAddress;

  var dayWeatherData = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    createSearch(location);
  }

  void createSearch(String inputLocationData) async {
    try {
      String searchApiUrlFinal = weatherApiUrl + 'weather?'
          + locationQueryParam + inputLocationData + appId;

      var searchResult = await http_package.get(Uri.parse(searchApiUrlFinal));
      var jsonResult = json.decode(searchResult.body);
      var mainObj = jsonResult["main"];
      var weatherObj = jsonResult["weather"][0];
      var sysObj = jsonResult["sys"];
      var coordObj = jsonResult["coord"];

      searchSevenDayForecast(
          coordObj["lat"].toString(), coordObj["lon"].toString());
      setState(() {
        dataFetched = true;
        location = jsonResult["name"] + ' - ' + sysObj["country"];
        temperature = (mainObj["temp"] - 273.15).round();
        feelsLike = (mainObj["feels_like"] - 273.15).round();
        pressure = mainObj["pressure"].round();
        humidity = mainObj["humidity"].round();
        backgroundImageName =
            weatherObj["main"].replaceAll(' ', '').toLowerCase();
        iconName = weatherObj["icon"];

        errorMessage = '';
      });
    } catch (error) {
      print(error);
      setState(() {
        dataFetched = true;
        errorMessage = 'Sorry currently no data available for this city';
      });
    }
  }

  void searchSevenDayForecast(String latitudeValue,
      String longitudeValue) async {
    try {
      String searchApiUrlFinal = weatherApiUrl + 'onecall?'
          + latitudeQParam + latitudeValue + longitudeQParam + longitudeValue +
          appId
          + '&exclude=current,minutely,hourly,alerts';

      var searchResult = await http_package.get(Uri.parse(searchApiUrlFinal));
      //var jsonResult = json.decode(searchResult.body);
      //var mainObj = jsonResult["daily"];
      setState(() {
        sevenDayForcast = searchResult.body;
        errorMessage = '';
      });
    } catch (error) {
      setState(() {
        errorMessage = 'Sorry currently no data available for this city';
      });
    }
  }

  void searchLocationDetails(String inputData) {
    setState(() {
      dataFetched = false;
      errorMessage = '';
    });

    if (inputData!='') {
      createSearch(inputData);
    } else {
      setState(() {
        dataFetched = true;
        errorMessage = 'Enter Location To Search!..';
      });
    }
  }

  getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() {
        currentPosition = position;
      });
      getCurrentLocationAddress();
    }).catchError((e) {
      print(e);
    });
  }

  getCurrentLocationAddress() async {
    try {
      List<Placemark> placemarkList = await
      placemarkFromCoordinates(
          currentPosition.latitude, currentPosition.longitude);

      Placemark place = placemarkList[0];
      setState(() {
        positionAddress =
        "${place.locality}, ${place.postalCode}, ${place.country}";
      });

      searchLocationDetails(place.locality!);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    var jsonResult = json.decode(sevenDayForcast);
    var mainObj = jsonResult["daily"];
    print('$iconSearchUrl$iconName$iconPostName');

    var imageIcon = Image.network(
      '$iconSearchUrl$iconName$iconPostName', width: 100.0,);
    return MaterialApp(
      home: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.dstATop),
            image: AssetImage(
                'lib/assets/images/$backgroundImageName.jpg'
            ),
          ),
        ),
        child: dataFetched == false ? Center(
          child: CircularProgressIndicator(),
        ) : Scaffold(
          appBar: AppBar(actions: [
            Padding(
              padding: const EdgeInsets.only(right: 18.0, top: 2.0),
              child: GestureDetector(
                onTap: () =>
                {
                  getCurrentLocation(),
                },
                child: Icon(Icons.location_city_rounded, size: 40.0,),
              ),
            )
          ],
            backgroundColor: Colors.transparent,
            elevation: 0.0,
          ),
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                children: [
                  Center(
                    child: Image.network(
                          '$iconSearchUrl$iconName$iconPostName', width: 100.0,),
                      //errorBuilder: (context, exception, stackTrack) => Icon(Icons.error_outline_rounded,),
                      //loadingBuilder: (context, exception, stackTrack) => CircularProgressIndicator(),
                    //),
                  ),
                  Center(
                    child: Text(
                      temperature.toString() + ' °C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 60.0,
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      location,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 45.0,
                      ),
                    ),
                  )
                ],
              ),
              mainObj!=null?SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 1; i < 8; i++)
                      sevenDayWeatherForcastWidget(json.encode(mainObj[i])),
                  ],
                ),
              ):SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    sevenDayWeatherForcastWidgetLoading(),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 280.0,
                    child: TextField(
                      onSubmitted: (String input) {
                        searchLocationDetails(input);
                      },
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter search location..',
                        hintStyle: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red, fontSize: 18.0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sevenDayWeatherForcastWidget(String jsonString) {
    var jsonForcastObj = json.decode(jsonString);

    var forecastDate = new DateTime.fromMillisecondsSinceEpoch(jsonForcastObj["dt"] * 1000);
    int maxTemperature = (jsonForcastObj["temp"]["max"] - 273.15).round();
    int minTemperature = (jsonForcastObj["temp"]["min"] - 273.15).round();
    String dayIconName = jsonForcastObj["weather"][0]["icon"].toString();

    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(205, 212, 228, 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              Text(
                new DateFormat.E().format(forecastDate),
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
              Text(
                new DateFormat.MMMd().format(forecastDate),
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                child: Image.network(
                  '$iconSearchUrl' + '$dayIconName' + '$iconPostName',
                  width: 50,
                ),
              ),
              Text(
                'High: $maxTemperature °C',
                style: TextStyle(color: Colors.white, fontSize: 20.0),
              ),
              Text(
                'Low: $minTemperature °C',
                style: TextStyle(color: Colors.white, fontSize: 20.0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget sevenDayWeatherForcastWidgetLoading() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(205, 212, 228, 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              CircularProgressIndicator(),
              Text(
                'Loading',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
