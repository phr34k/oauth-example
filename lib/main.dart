import 'dart:io' show HttpServer;

import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:oauth2_client/access_token_response.dart';
import 'package:oauth2_client/google_oauth2_client.dart';
import 'package:oauth2_client/src/token_storage.dart';
import 'package:oauth2_client/interfaces.dart';
import 'package:oauth2_client/oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp(LocalMeOAuth2Client(customUriScheme: 'io.liquid.example')));
}

//overloaded oauth helper class to force token to be regenerated oauth2_client
class OAuth2HelperEx extends OAuth2Helper {
  OAuth2HelperEx(OAuth2Client client,
      {required int grantType,
      required String clientId,
      String? clientSecret,
      List<String>? scopes,
      bool enablePKCE = true,
      bool enableState = true,
      Function? afterAuthorizationCodeCb,
      Map<String, dynamic>? authCodeParams,
      Map<String, dynamic>? accessTokenParams,
      BaseWebAuth? webAuthClient,
      Map<String, dynamic>? webAuthOpts,
      TokenStorage? tokenStorage})
      : super(client,
            grantType: grantType,
            clientId: clientId,
            clientSecret: clientSecret,
            scopes: scopes,
            enablePKCE: enablePKCE,
            enableState: enableState,
            tokenStorage: tokenStorage,
            afterAuthorizationCodeCb: afterAuthorizationCodeCb,
            authCodeParams: authCodeParams,
            accessTokenParams: accessTokenParams,
            webAuthClient: webAuthClient,
            webAuthOpts: webAuthOpts);

  @override
  Future<AccessTokenResponse?> getTokenFromStorage() async {
    return null;
  }
}

//dummy oauth provider because oauth2_client uses flutter_web_oauth under the hood
class LocalMeOAuth2Client extends OAuth2Client {
  LocalMeOAuth2Client({required String customUriScheme})
      : super(
            authorizeUrl: 'http://localtest.me:43823/',
            tokenUrl: 'http://localtest.me:43823/gettoken',
            redirectUri: 'io.liquid.example:/oauth2redirect',
            customUriScheme: 'io.liquid.example') {
    startServer();
  }

  Future<void> startServer() async {
    final server = await HttpServer.bind('127.0.0.1', 43823);

    server.listen((req) async {
      if (req.uri.path.startsWith('/favicon.ico')) {
        req.response.headers.add('Content-Type', 'text/html');
        req.response.write("");
        req.response.close();
      } else if (req.uri.path == '/') {
        if (req.uri.queryParameters['response_type'] == 'code') {
          var redirect_uri = req.uri.queryParameters['redirect_uri'];
          var state = req.uri.queryParameters['state'];

          var html = """<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Grant Access to Flutter</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html, body { margin: 0; padding: 0; }

    main {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      font-family: -apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif,Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol;
    }

    #icon {
      font-size: 96pt;
    }

    #text {
      padding: 2em;
      max-width: 260px;
      text-align: center;
    }

    #button a {
      display: inline-block;
      padding: 6px 12px;
      color: white;
      border: 1px solid rgba(27,31,35,.2);
      border-radius: 3px;
      background-image: linear-gradient(-180deg, #34d058 0%, #22863a 90%);
      text-decoration: none;
      font-size: 14px;
      font-weight: 600;
    }

    #button a:active {
      background-color: #279f43;
      background-image: none;
    }
  </style>
</head>
<body>
  <main>
    <div id="icon">&#x1F3C7;</div>
    <div id="text">Press the button below to sign in using your Localtest.me account.</div>
    <div id="button"><a href="${redirect_uri}?code=1337&state=${state}">Sign in</a></div>
  </main>
</body>
</html>
""";

          req.response.headers.add('Content-Type', 'text/html');
          req.response.write(html);
          req.response.close();
        } else {
          req.response.headers.add('Content-Type', 'text/html');
          req.response.write("hello");
          req.response.close();
        }
      } else {
        req.response.headers.add('Content-Type', 'text/html');
        req.response.write("");
        req.response.close();
      }
    });
  }

  @override
  Future<AccessTokenResponse> getTokenWithAuthCodeFlow(
      {required String clientId,
      List<String>? scopes,
      String? clientSecret,
      bool enablePKCE = true,
      bool enableState = true,
      String? state,
      String? codeVerifier,
      Function? afterAuthorizationCodeCb,
      Map<String, dynamic>? authCodeParams,
      Map<String, dynamic>? accessTokenParams,
      httpClient,
      BaseWebAuth? webAuthClient,
      Map<String, dynamic>? webAuthOpts}) async {
    AccessTokenResponse? tknResp;

    var authResp = await requestAuthorization(
        webAuthClient: webAuthClient,
        clientId: clientId,
        scopes: scopes,
        codeChallenge: null,
        enableState: enableState,
        state: state,
        customParams: authCodeParams,
        webAuthOpts: webAuthOpts);

    if (authResp.isAccessGranted()) {
      if (afterAuthorizationCodeCb != null) afterAuthorizationCodeCb(authResp);

      tknResp = await requestAccessToken(
          httpClient: httpClient,
          //If the authorization request was successfull, the code must be set
          //otherwise an exception is raised in the OAuth2Response constructor
          code: authResp.code!,
          clientId: clientId,
          scopes: scopes,
          clientSecret: clientSecret,
          codeVerifier: codeVerifier,
          customParams: accessTokenParams);
    } else {
      tknResp = AccessTokenResponse.errorResponse();
    }

    return tknResp;
  }
}

class MyApp extends StatelessWidget {
  final LocalMeOAuth2Client fakeOauth;
  const MyApp(this.fakeOauth, {Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const String clientId =
        String.fromEnvironment('CLIENT_ID', defaultValue: '');

    //Then, instantiate the helper passing the previously instantiated client
    OAuth2Helper oauth2Helper = OAuth2HelperEx(
        /*
        GoogleOAuth2Client(
            customUriScheme:
                'io.liquid.example', //Must correspond to the AndroidManifest's "android:scheme" attribute
            redirectUri: 'io.liquid.example:/oauth2redirect' //Can be any URI, but the scheme part must correspond to the customeUriScheme
            ),
        */
        fakeOauth,
        grantType: OAuth2Helper.AUTHORIZATION_CODE,
        clientId: clientId,
        //clientSecret: 'your_client_secret',
        scopes: ['https://www.googleapis.com/auth/userinfo.email']);

    return MultiProvider(
        providers: [
          Provider<OAuth2Helper>(create: (_) => oauth2Helper),
        ],
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            // This is the theme of your application.
            //
            // Try running your application with "flutter run". You'll see the
            // application has a blue toolbar. Then, without quitting the app, try
            // changing the primarySwatch below to Colors.green and then invoke
            // "hot reload" (press "r" in the console where you ran "flutter run",
            // or simply save your changes to "hot reload" in a Flutter IDE).
            // Notice that the counter didn't reset back to zero; the application
            // is not restarted.
            primarySwatch: Colors.blue,
          ),
          home: const MyHomePage(title: 'Flutter Demo Home Page'),
        ));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<bool>? future;

  Future<bool> perform() async {
    try {
      await Provider.of<OAuth2Helper>(context, listen: false).getToken();
      return Future.value(true);
    } catch (error, stacktrace) {
      return Future.error(error, stacktrace);
    }
  }

  @override
  void initState() {
    //startServer();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: FutureBuilder(
          future: future,
          builder: (_, __) {
            if (__.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (__.connectionState == ConnectionState.done) {
              return Text(
                  __.hasError ? __.error.toString() : __.data.toString());
            } else {
              return Container();
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() {
          future = perform();
        }),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
