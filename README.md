# CHAT APP IN FLUTTER USING GOOGLE FIREBASE
 Chat App in Flutter using Google Firebase

# Introduction:
 In this article we will learn how to create chat app in flutter using Google Firebase as backend. This article consists of number of articles in which you will learn 1. OTP Authentication in Flutter 2. Chat App Data Structure In Firebase Firestore 3. Pagination In Flutter Using Firebase Cloud Firestore 4. Upload Image File To Firebase Storage Using Flutter. I have divided chat app series in multiple articles, you will learn lots of stuff regarding flutter in this flutter chat app series. So let’s begin our app.

# Output:
![Chat App in Flutte using Google Firebase](https://raw.githubusercontent.com/myvsparth/flutter_chat_app/master/screenshots/1.png)

# Plugin Required: 
 firebase_auth: // for firebase otp authentication
 shared_preferences: ^0.5.3+1 // for storing user credentials persistence
 cloud_firestore: ^0.12.7 // to access firebase real time database
 contact_picker: ^0.0.2 // to add friends from contact list
 image_picker: ^0.6.0+17 // to select image from device
 firebase_storage: ^3.0.3 // to send image to user for that we need to store image on  server
 photo_view: ^0.4.2 // to view sent and received image in expanded view

# Programming Steps:
1. First and basic step to create new application in flutter. If you are a beginner in flutter then you can check my blog Create a first app in Flutter. I have created an app named as “flutter_chat_app”

2. Open the pubspec.yaml file in your project and add the following dependencies into it.
```
dependencies:
 flutter:
   sdk: flutter
 cupertino_icons: ^0.1.2
 firebase_auth:
 shared_preferences: ^0.5.3+1
 cloud_firestore: ^0.12.7
 contact_picker: ^0.0.2
 image_picker: ^0.6.0+17
 firebase_storage: ^3.0.3
 photo_view: ^0.4.2
```

3. Now we need to setup firebase project to provide authentication and storage feature. I have placed important implementation below but you can study full article OTP Authentication in Flutter , Chat App Data Structure In Firebase Firestore. Following is the OTP Authentication (registration_page.dart) Programming Implementation.
```
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
```

4. Now, we will implement add friend from contact list. Following is the programming implementation for access contacts from the device and add them as a friend to chat.
```
 openContacts() async {
   Contact contact = await _contactPicker.selectContact();
   if (contact != null) {
     String phoneNumber = contact.phoneNumber.number
         .toString()
         .replaceAll(new RegExp(r"\s\b|\b\s"), "")
         .replaceAll(new RegExp(r'[^\w\s]+'), '');
     if (phoneNumber.length == 10) {
       phoneNumber = '+91$phoneNumber';
     }
     if (phoneNumber.length == 12) {
       phoneNumber = '+$phoneNumber';
     }
     if (phoneNumber.length == 13) {
       DocumentReference mobileRef = db
           .collection("mobiles")
           .document(phoneNumber.replaceAll(new RegExp(r'[^\w\s]+'), ''));
       await mobileRef.get().then((documentReference) {
         if (documentReference.exists) {
           contactsReference.add({
             'uid': documentReference['uid'],
             'name': contact.fullName,
             'mobile': phoneNumber.replaceAll(new RegExp(r'[^\w\s]+'), ''),
           });
         } else {
           print('User Not Registered');
         }
       }).catchError((e) {});
     } else {
       print('Wrong Mobile Number');
     }
   }
 }
```

5. Now, we will implement chat screen in which usee will send text and image message to friend and vice versa. Following is the programming implementation for that. chat_page.dart. Pagination and image upload both are covered in this page. For full article reference please see  Pagination In Flutter Using Firebase Cloud Firestore, Upload Image File To Firebase Storage Using Flutter.
```
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/pages/gallary_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
 
class ChatPage extends StatefulWidget {
 final SharedPreferences prefs;
 final String chatId;
 final String title;
 ChatPage({this.prefs, this.chatId,this.title});
 @override
 ChatPageState createState() {
   return new ChatPageState();
 }
}
 
class ChatPageState extends State<ChatPage> {
 final db = Firestore.instance;
 CollectionReference chatReference;
 final TextEditingController _textController =
     new TextEditingController();
 bool _isWritting = false;
 
 @override
 void initState() {
   super.initState();
   chatReference =
       db.collection("chats").document(widget.chatId).collection('messages');
 }
 
 List<Widget> generateSenderLayout(DocumentSnapshot documentSnapshot) {
   return <Widget>[
     new Expanded(
       child: new Column(
         crossAxisAlignment: CrossAxisAlignment.end,
         children: <Widget>[
           new Text(documentSnapshot.data['sender_name'],
               style: new TextStyle(
                   fontSize: 14.0,
                   color: Colors.black,
                   fontWeight: FontWeight.bold)),
           new Container(
             margin: const EdgeInsets.only(top: 5.0),
             child: documentSnapshot.data['image_url'] != ''
                 ? InkWell(
                     child: new Container(
                       child: Image.network(
                         documentSnapshot.data['image_url'],
                         fit: BoxFit.fitWidth,
                       ),
                       height: 150,
                       width: 150.0,
                       color: Color.fromRGBO(0, 0, 0, 0.2),
                       padding: EdgeInsets.all(5),
                     ),
                     onTap: () {
                       Navigator.of(context).push(
                         MaterialPageRoute(
                           builder: (context) => GalleryPage(
                             imagePath: documentSnapshot.data['image_url'],
                           ),
                         ),
                       );
                     },
                   )
                 : new Text(documentSnapshot.data['text']),
           ),
         ],
       ),
     ),
     new Column(
       crossAxisAlignment: CrossAxisAlignment.end,
       children: <Widget>[
         new Container(
             margin: const EdgeInsets.only(left: 8.0),
             child: new CircleAvatar(
               backgroundImage:
                   new NetworkImage(documentSnapshot.data['profile_photo']),
             )),
       ],
     ),
   ];
 }
 
 List<Widget> generateReceiverLayout(DocumentSnapshot documentSnapshot) {
   return <Widget>[
     new Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: <Widget>[
         new Container(
             margin: const EdgeInsets.only(right: 8.0),
             child: new CircleAvatar(
               backgroundImage:
                   new NetworkImage(documentSnapshot.data['profile_photo']),
             )),
       ],
     ),
     new Expanded(
       child: new Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: <Widget>[
           new Text(documentSnapshot.data['sender_name'],
               style: new TextStyle(
                   fontSize: 14.0,
                   color: Colors.black,
                   fontWeight: FontWeight.bold)),
           new Container(
             margin: const EdgeInsets.only(top: 5.0),
             child: documentSnapshot.data['image_url'] != ''
                 ? InkWell(
                     child: new Container(
                       child: Image.network(
                         documentSnapshot.data['image_url'],
                         fit: BoxFit.fitWidth,
                       ),
                       height: 150,
                       width: 150.0,
                       color: Color.fromRGBO(0, 0, 0, 0.2),
                       padding: EdgeInsets.all(5),
                     ),
                     onTap: () {
                       Navigator.of(context).push(
                         MaterialPageRoute(
                           builder: (context) => GalleryPage(
                             imagePath: documentSnapshot.data['image_url'],
                           ),
                         ),
                       );
                     },
                   )
                 : new Text(documentSnapshot.data['text']),
           ),
         ],
       ),
     ),
   ];
 }
 
 generateMessages(AsyncSnapshot<QuerySnapshot> snapshot) {
   return snapshot.data.documents
       .map<Widget>((doc) => Container(
             margin: const EdgeInsets.symmetric(vertical: 10.0),
             child: new Row(
               children: doc.data['sender_id'] != widget.prefs.getString('uid')
                   ? generateReceiverLayout(doc)
                   : generateSenderLayout(doc),
             ),
           ))
       .toList();
 }
 
 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: Text(widget.title),
     ),
     body: Container(
       padding: EdgeInsets.all(5),
       child: new Column(
         children: <Widget>[
           StreamBuilder<QuerySnapshot>(
             stream: chatReference.orderBy('time',descending: true).snapshots(),
             builder: (BuildContext context,
                 AsyncSnapshot<QuerySnapshot> snapshot) {
               if (!snapshot.hasData) return new Text("No Chat");
               return Expanded(
                 child: new ListView(
                   reverse: true,
                   children: generateMessages(snapshot),
                 ),
               );
             },
           ),
           new Divider(height: 1.0),
           new Container(
             decoration: new BoxDecoration(color: Theme.of(context).cardColor),
             child: _buildTextComposer(),
           ),
           new Builder(builder: (BuildContext context) {
             return new Container(width: 0.0, height: 0.0);
           })
         ],
       ),
     ),
   );
 }
 
 IconButton getDefaultSendButton() {
   return new IconButton(
     icon: new Icon(Icons.send),
     onPressed: _isWritting
         ? () => _sendText(_textController.text)
         : null,
   );
 }
 
 Widget _buildTextComposer() {
   return new IconTheme(
       data: new IconThemeData(
         color: _isWritting
             ? Theme.of(context).accentColor
             : Theme.of(context).disabledColor,
       ),
       child: new Container(
         margin: const EdgeInsets.symmetric(horizontal: 8.0),
         child: new Row(
           children: <Widget>[
             new Container(
               margin: new EdgeInsets.symmetric(horizontal: 4.0),
               child: new IconButton(
                   icon: new Icon(
                     Icons.photo_camera,
                     color: Theme.of(context).accentColor,
                   ),
                   onPressed: () async {
                     var image = await ImagePicker.pickImage(
                         source: ImageSource.gallery);
                     int timestamp = new DateTime.now().millisecondsSinceEpoch;
                     StorageReference storageReference = FirebaseStorage
                         .instance
                         .ref()
                         .child('chats/img_' + timestamp.toString() + '.jpg');
                     StorageUploadTask uploadTask =
                         storageReference.putFile(image);
                     await uploadTask.onComplete;
                     String fileUrl = await storageReference.getDownloadURL();
                     _sendImage(messageText: null, imageUrl: fileUrl);
                   }),
             ),
             new Flexible(
               child: new TextField(
                 controller: _textController,
                 onChanged: (String messageText) {
                   setState(() {
                     _isWritting = messageText.length > 0;
                   });
                 },
                 onSubmitted: _sendText,
                 decoration:
                     new InputDecoration.collapsed(hintText: "Send a message"),
               ),
             ),
             new Container(
               margin: const EdgeInsets.symmetric(horizontal: 4.0),
               child: getDefaultSendButton(),
             ),
           ],
         ),
       ));
 }
 
 Future<Null> _sendText(String text) async {
   _textController.clear();
   chatReference.add({
     'text': text,
     'sender_id': widget.prefs.getString('uid'),
     'sender_name': widget.prefs.getString('name'),
     'profile_photo': widget.prefs.getString('profile_photo'),
     'image_url': '',
     'time': FieldValue.serverTimestamp(),
   }).then((documentReference) {
     setState(() {
       _isWritting = false;
     });
   }).catchError((e) {});
 }
 
 void _sendImage({String messageText, String imageUrl}) {
   chatReference.add({
     'text': messageText,
     'sender_id': widget.prefs.getString('uid'),
     'sender_name': widget.prefs.getString('name'),
     'profile_photo': widget.prefs.getString('profile_photo'),
     'image_url': imageUrl,
     'time': FieldValue.serverTimestamp(),
   });
 }
}
```

6. Great you are done with chat app in flutter using google firebase firestore. Please download our source code attached and run the code on device or emulator.

## NOTE:
 PLEASE CHECK OUT GIT REPO FOR FULL SOURCE CODE. YOU NEED TO ADD YOUR google-services.json FILE IN ANDROID => APP FOLDER.

## Possible Errors:
1. flutter barcode scan Failed to notify project evaluation listener. > java.lang.AbstractMethodError (no error message)

2. Android dependency 'androidx.core:core' has different version for the compile (1.0.0) and runtime (1.0.1) classpath. You should manually set the same version via DependencyResolution

3. import androidx.annotation.NonNull;

## Solution:
1 & 2. In android/build.grader change the version 
classpath 'com.android.tools.build:gradle:3.3.1'

3. Put 
android.useAndroidX=true
android.enableJetifier=true
In android/gradle.properties file

 Git: https://github.com/myvsparth/flutter_chat_app

## Related Tags: Flutter, Chat App, Dart, Android, iOS, Chat App Source Code, Chat App Demo