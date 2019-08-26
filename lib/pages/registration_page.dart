import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_app/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationPage extends StatefulWidget {
  final SharedPreferences prefs;
  RegistrationPage({this.prefs});
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  String phoneNo;
  String smsOTP;
  String verificationId;
  String errorMessage = '';
  FirebaseAuth _auth = FirebaseAuth.instance;
  final db = Firestore.instance;

  @override
  initState() {
    super.initState();
  }

  Future<void> verifyPhone() async {
    final PhoneCodeSent smsOTPSent = (String verId, [int forceCodeResend]) {
      this.verificationId = verId;
      smsOTPDialog(context).then((value) {});
    };
    try {
      await _auth.verifyPhoneNumber(
          phoneNumber: this.phoneNo, // PHONE NUMBER TO SEND OTP
          codeAutoRetrievalTimeout: (String verId) {
            //Starts the phone number verification process for the given phone number.
            //Either sends an SMS with a 6 digit code to the phone number specified, or sign's the user in and [verificationCompleted] is called.
            this.verificationId = verId;
          },
          codeSent:
              smsOTPSent, // WHEN CODE SENT THEN WE OPEN DIALOG TO ENTER OTP.
          timeout: const Duration(seconds: 20),
          verificationCompleted: (AuthCredential phoneAuthCredential) {
            print(phoneAuthCredential);
          },
          verificationFailed: (AuthException e) {
            print('${e.message}');
          });
    } catch (e) {
      handleError(e);
    }
  }

  Future<bool> smsOTPDialog(BuildContext context) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: Text('Enter SMS Code'),
            content: Container(
              height: 85,
              child: Column(children: [
                TextField(
                  onChanged: (value) {
                    this.smsOTP = value;
                  },
                ),
                (errorMessage != ''
                    ? Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red),
                      )
                    : Container())
              ]),
            ),
            contentPadding: EdgeInsets.all(10),
            actions: <Widget>[
              FlatButton(
                child: Text('Done'),
                onPressed: () {
                  _auth.currentUser().then((user) async {
                    signIn();
                  });
                },
              )
            ],
          );
        });
  }

  signIn() async {
    try {
      final AuthCredential credential = PhoneAuthProvider.getCredential(
        verificationId: verificationId,
        smsCode: smsOTP,
      );
      final FirebaseUser user = await _auth.signInWithCredential(credential);
      final FirebaseUser currentUser = await _auth.currentUser();
      assert(user.uid == currentUser.uid);
      Navigator.of(context).pop();
      DocumentReference mobileRef = db
          .collection("mobiles")
          .document(phoneNo.replaceAll(new RegExp(r'[^\w\s]+'), ''));
      await mobileRef.get().then((documentReference) {
        if (!documentReference.exists) {
          mobileRef.setData({}).then((documentReference) async {
            await db.collection("users").add({
              'name': "No Name",
              'mobile': phoneNo.replaceAll(new RegExp(r'[^\w\s]+'), ''),
              'profile_photo': "",
            }).then((documentReference) {
              widget.prefs.setBool('is_verified', true);
              widget.prefs.setString(
                'mobile',
                phoneNo.replaceAll(new RegExp(r'[^\w\s]+'), ''),
              );
              widget.prefs.setString('uid', documentReference.documentID);
              widget.prefs.setString('name', "No Name");
              widget.prefs.setString('profile_photo', "");

              mobileRef.setData({'uid': documentReference.documentID}).then(
                  (documentReference) async {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => HomePage(prefs: widget.prefs)));
              }).catchError((e) {
                print(e);
              });
            }).catchError((e) {
              print(e);
            });
          });
        } else {
          widget.prefs.setBool('is_verified', true);
          widget.prefs.setString(
            'mobile_number',
            phoneNo.replaceAll(new RegExp(r'[^\w\s]+'), ''),
          );
          widget.prefs.setString('uid', documentReference["uid"]);
          widget.prefs.setString('name', documentReference["name"]);
          widget.prefs
              .setString('profile_photo', documentReference["profile_photo"]);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomePage(prefs: widget.prefs),
            ),
          );
        }
      }).catchError((e) {});
    } catch (e) {
      handleError(e);
    }
  }

  handleError(PlatformException error) {
    switch (error.code) {
      case 'ERROR_INVALID_VERIFICATION_CODE':
        FocusScope.of(context).requestFocus(new FocusNode());
        setState(() {
          errorMessage = 'Invalid Code';
        });
        Navigator.of(context).pop();
        smsOTPDialog(context).then((value) {});
        break;
      default:
        setState(() {
          errorMessage = error.message;
        });

        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(10),
              child: TextField(
                decoration: InputDecoration(hintText: '+910000000000'),
                onChanged: (value) {
                  this.phoneNo = value;
                },
              ),
            ),
            (errorMessage != ''
                ? Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  )
                : Container()),
            SizedBox(
              height: 10,
            ),
            RaisedButton(
              onPressed: () {
                verifyPhone();
              },
              child: Text('Verify'),
              textColor: Colors.white,
              elevation: 7,
              color: Colors.blue,
            )
          ],
        ),
      ),
    );
  }
}
