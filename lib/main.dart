import 'package:flutter/material.dart';
import 'package:oauth2_client/google_oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const String clientId =
        String.fromEnvironment('CLIENT_ID', defaultValue: '');

    //Then, instantiate the helper passing the previously instantiated client
    OAuth2Helper oauth2Helper = OAuth2Helper(
        GoogleOAuth2Client(
            customUriScheme:
                'io.liquid.example', //Must correspond to the AndroidManifest's "android:scheme" attribute
            redirectUri: 'io.liquid.example:/oauth2redirect' //Can be any URI, but the scheme part must correspond to the customeUriScheme
            ),
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
      await Provider.of<OAuth2Helper>(context, listen: false)
          .get('https://www.googleapis.com/oauth2/v2/userinfo');
      return Future.value(true);
    } catch (error, stacktrace) {
      return Future.error(error, stacktrace);
    }
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
