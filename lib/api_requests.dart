import 'package:pop_app/secure_storage.dart';
import 'package:pop_app/models/store.dart';
import 'package:pop_app/models/user.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

List<Map<String, String>> routes = [
  {"route": "login", "method": "POST"},
  {"route": "registracija", "method": "POST"},
  {"route": "proizvodi", "method": "GET"},
  {"route": "proizvodi", "method": "POST"},
  {"route": "paketi", "method": "POST"},
  {"route": "novcanik", "method": "POST"},
  {"route": "racuni", "method": "POST"},
  {"route": "trgovine", "method": "POST"},
  {"route": "korisnici", "method": "POST"},
];

enum Routes { login, registracija, proizvodi, paketi, novcanik, racuni, trgovine, korisnici }

class ApiRequestManager {
  static const String root = "https://cortex.foi.hr/pop/api/v1/";
  static String? _token;

  static String? getToken() => _token;

  /// Call an API route
  static Uri route(Routes route) => Uri.parse("$root${route.name}.php");

  static Future login(String username, String password) async {
    var fm = {"KorisnickoIme": username, "Lozinka": password};

    http.Response response = await http.post(
      body: fm,
      route(Routes.login),
    );
    var responseData = json.decode(response.body);
    _updateTokenData(responseData);

    return responseData;
  }

  static void _updateTokenData(responseData) {
    try {
      var tokenData = responseData["DATA"]["Token"];
      _token = tokenData;
    } catch (e) {
      SecureStorage.setUserData(json.encode("{}"));
    }
  }

  static Future register(User user) async {
    var fm = {
      "Ime": user.firstName,
      "Prezime": user.lastName,
      "Lozinka": user.password,
      "Email": user.email,
      "KorisnickoIme": user.username
    };

    http.Response response = await http.post(
      body: fm,
      route(Routes.registracija),
    );

    var responseData = json.decode(response.body);
    _updateTokenData(responseData);

    return responseData;
  }

  static Future<dynamic> getAllStores(User user) async {
    var fm = {
      "Token": _token,
      "KorisnickoIme": user.username,
      "Readall": "True",
    };

    dynamic responseData;
    responseData = await _executeWithToken(user, () async {
      http.Response response = await http.post(body: fm, route(Routes.trgovine));
      return response.bodyBytes;
    });

    return responseData;
  }

  static Future<Store> createStore(User user, String storeName) async {
    var fm = {
      "Token": _token,
      "KorisnickoIme": user.username,
      "CREATESTORE": "True",
      "NazivTrgovine": storeName
    };

    dynamic responseData;

    responseData = await _executeWithToken(user, () async {
      http.Response response = await http.post(body: fm, route(Routes.trgovine));
      return response.bodyBytes;
    });

    return Store(responseData["DATA"]["Id_Trgovine"], responseData["DATA"]["NazivTrgovine"], 0, 0);
  }

  static Future<bool> assignStore(User user, Store store) async {
    var fm = {
      "Token": _token,
      "KorisnickoIme": user.username,
      "ASSIGNSTORESELF": "True",
      "Id_Trgovine": store.storeId.toString()
    };

    dynamic responseData;

    responseData = await _executeWithToken(user, () async {
      http.Response response = await http.post(body: fm, route(Routes.trgovine));
      dynamic body = response.bodyBytes;
      return body;
    });

    return (responseData["STATUSMESSAGE"] == "STORE ASSIGNED");
  }

  static Future<bool> assignRole(User user) async {
    if (user.getRole() == null) {
      return false;
    }

    var fm = {
      "Token": _token,
      "KorisnickoIme": user.username,
      "SETOWNROLE": "True",
      "RoleId": user.getRole()!.roleId.toString()
    };

    dynamic responseData;
    responseData = await _executeWithToken(user, () async {
      http.Response response = await http.post(body: fm, route(Routes.korisnici));
      return response.bodyBytes;
    });

    return (responseData["STATUSMESSAGE"] == "OWN ROLE SET");
  }

  /// Wraps whatever fetching logic into a token check.
  /// If the server reports token is invalid, this method attempts login once.
  /// If the new token is still invalid, method returns null instead of response.
  /// [requestCallback] should return a response body!
  static Future<dynamic> _executeWithToken(User user, dynamic requestCallback) async {
    int attempts = 0;

    dynamic responseData;
    bool isTokenValid = false;
    do {
      dynamic body = await requestCallback();
      responseData = jsonDecode(utf8.decode(body));
      isTokenValid = _isTokenValid(responseData);
      if (!isTokenValid) {
        login(user.username, user.password);
      }
    } while (!isTokenValid && ++attempts != 2);

    if (attempts == 2) {
      responseData = null;
    }

    return responseData;
  }

  static bool _isTokenValid(responseData) {
    return responseData["STATUSMESSAGE"] != "OLD TOKEN";
  }

  static Future<List> getAllPackages(User user) async {
    var fm = {"Token": _token, "KorisnickoIme": user.username, "GET": "True"};
    dynamic responseData;
    responseData = await _executeWithToken(user, () async {
      http.Response response = await http.post(body: fm, route(Routes.paketi));
      return response.bodyBytes;
    });
    return [responseData];
  }

  static Future<List> getAllProducts(User user) async {
    var fm = {"Token": _token, "KorisnickoIme": user.username, "GET": "True"};
    dynamic responseData;
    responseData = await _executeWithToken(user, () async {
      http.Response response = await http.post(body: fm, route(Routes.proizvodi));
      return response.bodyBytes;
    });
    return [responseData];
  }
}
