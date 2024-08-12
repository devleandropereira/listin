import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_listin/_core/data/local_data_handler.dart';
import 'package:flutter_listin/_core/services/dio_endpoints.dart';
import 'package:flutter_listin/_core/services/dio_interceptor.dart';
import 'package:flutter_listin/listins/data/database.dart';

class DioService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: DioEndpoints.devBaseUrl,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 3)
    )
  );

  DioService() {
    _dio.interceptors.add(DioInterceptor());
  }

  Future<String?> saveLocalToServer(AppDatabase appDatabase) async {
    Map<String, dynamic> localData = await LocalDataHandler().localDataToMap(appdatabase: appDatabase);

    try {
      await _dio.put(DioEndpoints.listins, data: json.encode(localData["listins"],));
    } on DioException catch(e) {
      if (e.response != null && e.response!.data != null) {
        return e.response!.data!.toString();
      } else {
        return e.message;
      }
    } on Exception {
      return "Um erro aconteceu";
    }

  }

  Future<void> getDataFromServer(AppDatabase appDatabase) async {
    Response response = await _dio.get(DioEndpoints.listins, queryParameters: {
      "orderBy": '"name"',
      "startAt": 0
    });
    if (response.data != null) {
      Map<String, dynamic> map = {};

      if (response.data.runtimeType == List) {
        if ((response.data as List<dynamic>).isNotEmpty) {
          map["listins"] = response.data;

          await LocalDataHandler().mapToLocalData(map: map, appdatabase: appDatabase);
        }
      } else {
        List<Map<String, dynamic>> tempList = [];

        for (var mapResponse in (response.data as Map).values) {
          tempList.add(mapResponse);
        }
        map["listins"] = tempList;
      }
      await LocalDataHandler().mapToLocalData(map: map, appdatabase: appDatabase);
    }
  }

  Future<void> clearServerData() async {
    await _dio.delete(DioEndpoints.listins);
  }

}