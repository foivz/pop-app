// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:pop_app/models/initial_invoice.dart';
import 'package:pop_app/models/invoice.dart';
import 'package:pop_app/models/item.dart';
import 'package:pop_app/models/package_data.dart';
import 'package:pop_app/models/product_data.dart';
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

  static Future register(NewUser user) async {
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

  static void _updateTokenData(responseData) {
    try {
      var tokenData = responseData["DATA"]["Token"];
      _token = tokenData;
    } catch (e) {
      SecureStorage.setUserData(json.encode("{}"));
    }
  }

  /// Wraps whatever fetching logic into a token check.
  /// If the server reports token is invalid, this method attempts login once.
  /// If the new token is still invalid, method returns null instead of response.
  /// [requestCallback] should return a response.bodyBytes in order to parse UTF-8 chars!
  static Future<dynamic> _executeWithToken(dynamic requestCallback) async {
    int attempts = 0;

    dynamic responseData;
    bool isTokenValid = false;
    do {
      dynamic body = await requestCallback();
      responseData = jsonDecode(utf8.decode(body));
      isTokenValid = _isTokenValid(responseData);
      if (!isTokenValid) {
        login(User.loggedIn.username, User.loggedIn.password);
      }
    } while (!isTokenValid && ++attempts != 2);

    if (attempts == 2) {
      responseData = null;
    }

    return responseData;
  }

  static Future<dynamic> getAllStores() async {
    var fm = {
      "Token": _token,
      "KorisnickoIme": User.loggedIn.username,
      "Readall": "True",
    };

    dynamic responseData;
    responseData = await _executeWithToken(() async {
      http.Response response = await http.post(body: fm, route(Routes.trgovine));
      return response.bodyBytes;
    });

    return responseData;
  }

  static Future<Store> createStore(String storeName) async {
    var fm = {
      "Token": _token,
      "KorisnickoIme": User.loggedIn.username,
      "CREATESTORE": "True",
      "NazivTrgovine": storeName
    };

    dynamic responseData;

    responseData = await _executeWithToken(() async {
      http.Response response = await http.post(body: fm, route(Routes.trgovine));
      return response.bodyBytes;
    });

    return Store(responseData["DATA"]["Id_Trgovine"], responseData["DATA"]["NazivTrgovine"], 0, 0);
  }

  static Future<bool> assignStore(Store store) async {
    var fm = {
      "Token": _token,
      "KorisnickoIme": User.loggedIn.username,
      "ASSIGNSTORESELF": "True",
      "Id_Trgovine": store.storeId.toString()
    };

    dynamic responseData;

    responseData = await _executeWithToken(() async {
      http.Response response = await http.post(body: fm, route(Routes.trgovine));
      dynamic body = response.bodyBytes;
      return body;
    });

    return (responseData["STATUSMESSAGE"] == "STORE ASSIGNED");
  }

  static Future<bool> setLoggedUsersRole() async {
    if (User.loggedIn.role == null) {
      return false;
    }

    var fm = {
      "Token": _token,
      "KorisnickoIme": User.loggedIn.username,
      "SETOWNROLE": "True",
      "RoleId": User.loggedIn.role!.roleId.toString()
    };

    dynamic responseData;
    responseData = await _executeWithToken(() async {
      http.Response response = await http.post(body: fm, route(Routes.korisnici));
      return response.bodyBytes;
    });

    return (responseData["STATUSMESSAGE"] == "OWN ROLE SET");
  }

  static Future<double> getBalance() async {
    if (User.loggedIn.role == null) {
      throw Exception("Can't get balance: user's role not set!");
    }

    final roleMap = {
      "buyer": "GETCLIENT",
      "seller": "GETSTORE",
    };

    var fm = {
      "Token": _token,
      "KorisnickoIme": User.loggedIn.username,
      roleMap[User.loggedIn.role!.roleName]: "True",
    };

    dynamic responseData;

    responseData = await _executeWithToken(() async {
      http.Response response = await http.post(
        body: fm,
        route(Routes.novcanik),
      );

      return response.bodyBytes;
    });

    double fetchedBalance;

    try {
      fetchedBalance = double.parse(responseData["DATA"]);
    } catch (e) {
      throw Exception("Can't get balance: ${responseData["STATUSMESSAGE"]}!");
    }

    return fetchedBalance;
  }

  static Future<List<Invoice>> getAllInvoices() async {
    var fm = {
      "Token": _token,
      "KorisnickoIme": User.loggedIn.username,
      "Readall": "True",
    };

    dynamic responseData;
    responseData = await _executeWithToken(() async {
      http.Response response = await http.post(body: fm, route(Routes.racuni));
      return response.bodyBytes;
    });

    List<Invoice> invoices = List<Invoice>.empty(growable: true);

    if (responseData["DATA"] != null) {
      for (var invoice in responseData["DATA"]) {
        invoices.add(Invoice.fromDynamicMap(invoice));
      }
    }

    return invoices;
  }

  /// Finalizes an invoice with a complete form data request body.
  static Future<Invoice?> _finalizeInvoice({required Map<String, String> fm}) async {
    dynamic responseData;
    responseData = await _executeWithToken(() async {
      http.Response response = await http.post(body: fm, route(Routes.racuni));
      return response.bodyBytes;
    });

    Invoice? invoice;

    if (responseData["STATUSMESSAGE"] == "MISSING AMOUNT") {
      throw Exception("The seller can't sell this much to you!");
    } else if (responseData["STATUSMESSAGE"] == "MISSING BALANCE") {
      throw Exception("You don't have enough funds left to proceed!");
    } else if (responseData["STATUSMESSAGE"] == "NO BUYING FROM OWN STORE") {
      throw Exception("You can't buy from your own store!");
    } else if (responseData["STATUSMESSAGE"] == "INVOICE FINALIZED") {
      invoice = Invoice.fromDynamicMap(responseData["DATA"]);
    }

    return invoice;
  }

  static Future<Invoice?> finalizeInvoiceViaQR(String code) async {
    return _finalizeInvoice(fm: {
      "Token": _token!,
      "KorisnickoIme": User.loggedIn.username,
      "CONFIRMSALE": "True",
      "Id_Racuna": code
    });
  }

  static Future<Invoice?> finalizeInvoiceViaCode(String code) async {
    return _finalizeInvoice(fm: {
      "Token": _token!,
      "KorisnickoIme": User.loggedIn.username,
      "CONFIRMSALEFROMCODE": "True",
      "Kod_Racuna": code
    });
  }

  static Future<InitialInvoice> generateInvoice(double discount, List<Item> items) async {
    Map<String, Object> fm = {
      "Token": _token!,
      "KorisnickoIme": User.loggedIn.username,
      "GENERATESALE": "True",
      "PopustRacuna": discount.toStringAsFixed(0),
    };

    for (int i = 0; i < items.length; i++) {
      fm["Itemi[$i]"] = items[i].id;
      fm["Kolicine[$i]"] = items[i].selectedForSelling.toString();
    }

    dynamic responseData;
    responseData = await _executeWithToken(() async {
      http.Response response = await http.post(body: fm, route(Routes.racuni));
      return response.bodyBytes;
    });

    if (responseData["STATUSMESSAGE"] == "INVOICE GENERATED") {
      return InitialInvoice(
          id: responseData["DATA"]["Id"], code: responseData["DATA"]["Kod_Racuna"]);
    } else if (responseData["STATUSMESSAGE"] == "MISSING AMOUNT") {
      throw Exception("You don't have so many items!\n"
          "Try to lower the amount you're trying to sell or edit products to add more!");
    } else {
      throw Exception("Something went wrong: ${responseData["STATUSMESSAGE"]}");
    }
  }

  static bool _isTokenValid(responseData) {
    return responseData["STATUSMESSAGE"] != "OLD TOKEN";
  }

  static Future<List> getAllPackages() async {
    var fm = {"Token": _token, "KorisnickoIme": User.loggedIn.username, "GET": "True"};
    dynamic responseData;
    responseData = await _executeWithToken(() async {
      http.Response response = await http.post(body: fm, route(Routes.paketi));
      return response.bodyBytes;
    });
    return [responseData];
  }

  static Future<List> getAllProducts() async {
    var fm = {"Readall": "True", "Token": _token, "KorisnickoIme": User.loggedIn.username};
    dynamic responseData;
    responseData = await _executeWithToken(() async {
      http.Response response = await http.post(body: fm, route(Routes.proizvodi));
      return response.bodyBytes;
    });
    return [responseData];
  }

  static Future addProductToStore(ProductData product) async {
    http.MultipartRequest req = http.MultipartRequest('POST', route(Routes.proizvodi));
    req.fields.addAll({
      "Token": _token!,
      "Naziv": product.title,
      "Opis": product.description,
      "Cijena": product.price.toString(),
      "Kolicina": product.remainingAmount.toString(),
      "KorisnickoIme": User.loggedIn.username,
    });
    if (product.imageFile != null)
      req.files.add(
        http.MultipartFile.fromBytes(
          'Slika',
          filename: 'Slika',
          await product.imageFile!.readAsBytes(),
        ),
      );
    http.StreamedResponse responseData;
    try {
      responseData = await req.send();
      return responseData;
    } catch (e) {
      throw Exception("Failed to connect");
    }
  }

  static Future addPackageToStore(PackageData package) async {
    http.MultipartRequest req = http.MultipartRequest('POST', route(Routes.paketi));
    req.fields.addAll({
      "Token": _token!,
      "ADD": "True",
      "Naziv": package.title,
      "Opis": package.description,
      "Popust": package.discount.toString(),
      "KolicinaPaketa": "1",
      "KorisnickoIme": User.loggedIn.username,
    });
    if (package.imageFile != null)
      req.files.add(
        http.MultipartFile.fromBytes(
          'Slika',
          filename: 'Slika',
          await package.imageFile!.readAsBytes(),
        ),
      );
    http.StreamedResponse responseData;
    try {
      responseData = await req.send();
      return responseData;
    } catch (e) {
      throw Exception("Failed to connect");
    }
  }

  static Future<bool> addProductsToPackage(List<int> ids, List<int> amounts, int packageId) async {
    User user = User.loggedIn;

    var fm = {
      "Token": _token,
      "KorisnickoIme": user.username,
      "ADDTOPACKET": "True",
      "Id_Paket": packageId.toString(),
    };

    for (int i = 0; i < ids.length; i++) {
      fm["Id_Proizvod[$i]"] = ids[i].toString();
      fm["Kolicina[$i]"] = amounts[i].toString();
    }

    dynamic responseData;
    responseData = await _executeWithToken(() async {
      http.Response response = await http.post(body: fm, route(Routes.paketi));
      return response.bodyBytes;
    });

    return (responseData["STATUSMESSAGE"] == "PRODUCT ADDED TO PACKET");
  }

  static Future deletePackage(String packageId) async {
    http.MultipartRequest req = http.MultipartRequest('POST', route(Routes.paketi));
    req.fields.addAll({
      "Token": _token!,
      "Id": packageId,
      "DELETE": true.toString(),
      "KorisnickoIme": User.loggedIn.username,
    });
    http.StreamedResponse responseData;
    try {
      responseData = await req.send();
      return responseData;
    } catch (e) {
      throw Exception("Failed to connect");
    }
  }

  static Future editPackage(PackageData package) async {
    http.MultipartRequest req = http.MultipartRequest('POST', route(Routes.paketi));
    req.fields.addAll({
      "Token": _token!,
      "UPDATE": true.toString(),
      "Id": package.id.toString(),
      "Naziv": package.title,
      "Opis": package.description,
      "Kolicina": "1",
      "Popust": package.discount.toString(),
      // slika
      "KorisnickoIme": User.loggedIn.username,
    });
    if (package.imageFile != null && package.imagePath == null) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'Slika',
          filename: 'Slika',
          await package.imageFile!.readAsBytes(),
        ),
      );
    } else if (package.imagePath != null) req.fields.addAll({"Slika": package.imagePath!});
    http.StreamedResponse responseData;
    try {
      responseData = await req.send();
      return responseData;
    } catch (e) {
      throw Exception("Failed to connect");
    }
  }

  static Future deleteProduct(String productId) async {
    http.MultipartRequest req = http.MultipartRequest('POST', route(Routes.proizvodi));
    req.fields.addAll({
      "Token": _token!,
      "Id": productId.toString(),
      "KorisnickoIme": User.loggedIn.username,
    });
    http.StreamedResponse responseData;
    try {
      responseData = await req.send();
      return responseData;
    } catch (e) {
      throw Exception("Failed to connect");
    }
  }

  static Future editProduct(ProductData product) async {
    http.MultipartRequest req = http.MultipartRequest('POST', route(Routes.proizvodi));
    req.fields.addAll({
      "Edit": true.toString(),
      "Token": _token!,
      "Id": product.id.toString(),
      "Naziv": product.title,
      "Opis": product.description,
      "Cijena": product.price.toString(),
      "Kolicina": product.remainingAmount.toString(),
      "KorisnickoIme": User.loggedIn.username,
    });
    if (product.imageFile != null && product.imagePath == null) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'Slika',
          filename: 'Slika',
          await product.imageFile!.readAsBytes(),
        ),
      );
    } else if (product.imagePath != null) req.fields.addAll({"Slika": product.imagePath!});
    http.StreamedResponse responseData;
    try {
      responseData = await req.send();
      return responseData;
    } catch (e) {
      throw Exception("Failed to connect");
    }
  }
}
