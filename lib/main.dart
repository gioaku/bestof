import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'src/authentication.dart';
import 'src/widgets.dart';
import 'utils/datetime.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => FireNotifier(),
      builder: (context, _) => App(),
    ),
  );
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BestOf',
      theme: ThemeData(
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
              highlightColor: Colors.deepPurple,
            ),
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BestOf'),
      ),
      body: Consumer<FireNotifier>(
        builder: (context, appState, _) => ListView(
          children: <Widget>[
            Authentication(
              email: appState.email,
              loginState: appState.loginState,
              startLoginFlow: appState.startLoginFlow,
              verifyEmail: appState.verifyEmail,
              signInWithEmailAndPassword: appState.signInWithEmailAndPassword,
              cancelRegistration: appState.cancelRegistration,
              registerAccount: appState.registerAccount,
              signOut: appState.signOut,
            ),
            BestofTodayView(appState._todayBestof, appState.loginState),
            //BestofYesterdayView(),
            //BestofRandomView(),
            AddBestof(appState.addBestof),
          ],
        ),

        /*Consumer<FireNotifier>(
            builder: (context, appState, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appState.loginState == ApplicationLoginState.loggedIn) ...[
                  Header('Discussion'),
                  GuestBook(
                    addMessage: (String message) =>
                        appState.addMessageToGuestBook(message),
                    messages: appState.guestBookMessages,
                  ),
                ],
              ],
            ),
          ),
          */
      ),
    );
  }
}

class BestofTodayView extends StatelessWidget {
  final List<Bestof> todayBestof;
  final loginState;
  BestofTodayView(this.todayBestof, this.loginState);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loginState == ApplicationLoginState.loggedIn) ...[
            Header('Today'),
            for (var bo in todayBestof) BestofTile('${bo.text}')
          ],
        ],
      ),
    );
  }
}

class AddBestof extends StatefulWidget {
  final addBestof;
  AddBestof(this.addBestof);

  @override
  _AddBestofState createState() => _AddBestofState();
}

class _AddBestofState extends State<AddBestof> {
  final _formKey = GlobalKey<FormState>(debugLabel: '_AddBestofState');
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Form(
            key: _formKey,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Leave a message',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your message to continue';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 8),
                StyledButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await widget.addBestof(_controller.text, 0);
                      _controller.clear();
                    }
                  },
                  child: Row(
                    children: [
                      SizedBox(width: 4),
                      Text('ADD'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class Bestof {
  Bestof({this.text, this.day});
  final text;
  final day;
}

class FireNotifier extends FireAuthNotifier {
  StreamSubscription<QuerySnapshot>? _todayBestofSub;
  List<Bestof> _todayBestof = [];
  List<Bestof> get todayBestof => _todayBestof;

  @override
  Future<void> init() async {
    await Firebase.initializeApp();

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        super.setLoginStateIn();
        /*
        var todayTimestamp = Timestamp(
            (DateTime(now.year, now.month, now.day - 1)
                    .millisecondsSinceEpoch ~/
                1000),
            0);
        
        */
        var bestofReference = FirebaseFirestore.instance.collection('bestof');
        _todayBestofSub = bestofReference
            /*
            */
            .where('date', isGreaterThanOrEqualTo: startOfToday())
            .where('date', isLessThanOrEqualTo: endOfToday())
            .where('user', isEqualTo: user.uid)
            .snapshots()
            .listen((snapshot) {
          _todayBestof = [];
          snapshot.docs.forEach((element) {
            _todayBestof.add(
              Bestof(
                text: element.data()['text'],
                day: element.data()['date'],
              ),
            );
          });
          notifyListeners();
        });
      } else {
        super.setLoginStateOut();
        _todayBestof = [];
        _todayBestofSub?.cancel();
      }
      notifyListeners();
    });
  }

  Future<DocumentReference> addBestof(String message, int daysAgo) {
    if (loginState != ApplicationLoginState.loggedIn) {
      throw Exception('Must be logged in');
    }
    return FirebaseFirestore.instance.collection('bestof').add({
      'text': message,
      'date': startOfDayAgo(daysAgo),
      'user': FirebaseAuth.instance.currentUser!.uid,
    });
  }
}
