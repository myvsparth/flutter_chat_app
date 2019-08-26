import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_app/pages/chat_page.dart';
import 'package:flutter_chat_app/pages/registration_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contact_picker/contact_picker.dart';

class HomePage extends StatefulWidget {
  final SharedPreferences prefs;
  HomePage({this.prefs});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  String _tabTitle = "Contacts";
  List<Widget> _children = [Container(), Container()];

  final db = Firestore.instance;
  final ContactPicker _contactPicker = new ContactPicker();
  CollectionReference contactsReference;
  DocumentReference profileReference;
  DocumentSnapshot profileSnapshot;

  final GlobalKey<FormState> _formStateKey = GlobalKey<FormState>();
  final _yourNameController = TextEditingController();
  bool editName = false;
  @override
  void initState() {
    super.initState();
    contactsReference = db
        .collection("users")
        .document(widget.prefs.getString('uid'))
        .collection('contacts');
    profileReference =
        db.collection("users").document(widget.prefs.getString('uid'));

    profileReference.snapshots().listen((querySnapshot) {
      profileSnapshot = querySnapshot;
      widget.prefs.setString('name', profileSnapshot.data["name"]);
      widget.prefs
          .setString('profile_photo', profileSnapshot.data["profile_photo"]);

      setState(() {
        _yourNameController.text = profileSnapshot.data["name"];
      });
    });
  }

  generateContactTab() {
    return Column(
      children: <Widget>[
        StreamBuilder<QuerySnapshot>(
          stream: contactsReference.snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) return new Text("No Contacts");
            return Expanded(
              child: new ListView(
                children: generateContactList(snapshot),
              ),
            );
          },
        )
      ],
    );
  }

  Future<void> getProfilePicture() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    StorageReference storageReference = FirebaseStorage.instance
        .ref()
        .child('profiles/${widget.prefs.getString('uid')}');
    StorageUploadTask uploadTask = storageReference.putFile(image);
    await uploadTask.onComplete;
    print('File Uploaded');
    String fileUrl = await storageReference.getDownloadURL();
    profileReference.updateData({'profile_photo': fileUrl});
  }

  generateProfileTab() {
    return Center(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            (profileSnapshot != null
                ? (profileSnapshot.data['profile_photo'] != null
                    ? InkWell(
                        child: Container(
                          width: 190.0,
                          height: 190.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              fit: BoxFit.fill,
                              image: NetworkImage(
                                  '${profileSnapshot.data['profile_photo']}'),
                            ),
                          ),
                        ),
                        onTap: () {
                          getProfilePicture();
                        },
                      )
                    : Container())
                : Container()),
            SizedBox(
              height: 20,
            ),
            (!editName && profileSnapshot != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Text('${profileSnapshot.data["name"]}'),
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          setState(() {
                            editName = true;
                          });
                        },
                      ),
                    ],
                  )
                : Container()),
            (editName
                ? Form(
                    key: _formStateKey,
                    autovalidate: true,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding:
                              EdgeInsets.only(left: 10, right: 10, bottom: 10),
                          child: TextFormField(
                            validator: (value) {
                              if (value.isEmpty) {
                                return 'Please Enter Name';
                              }
                              if (value.trim() == "")
                                return "Only Space is Not Valid!!!";
                              return null;
                            },
                            controller: _yourNameController,
                            decoration: InputDecoration(
                              focusedBorder: new UnderlineInputBorder(
                                  borderSide: new BorderSide(
                                      width: 2, style: BorderStyle.solid)),
                              labelText: "Your Name",
                              icon: Icon(
                                Icons.verified_user,
                              ),
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container()),
            (editName
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      RaisedButton(
                        child: Text(
                          'UPDATE',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          if (_formStateKey.currentState.validate()) {
                            profileReference
                                .updateData({'name': _yourNameController.text});
                            setState(() {
                              editName = false;
                            });
                          }
                        },
                        color: Colors.lightBlue,
                      ),
                      RaisedButton(
                        child: Text('CANCEL'),
                        onPressed: () {
                          setState(() {
                            editName = false;
                          });
                        },
                      )
                    ],
                  )
                : Container())
          ]),
    );
  }

  generateContactList(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.data.documents
        .map<Widget>(
          (doc) => InkWell(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey,
                  ),
                ),
              ),
              child: ListTile(
                title: Text(doc["name"]),
                subtitle: Text(doc["mobile"]),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
            onTap: () async {
              QuerySnapshot result = await db
                  .collection('chats')
                  .where('contact1', isEqualTo: widget.prefs.getString('uid'))
                  .where('contact2', isEqualTo: doc["uid"])
                  .getDocuments();
              List<DocumentSnapshot> documents = result.documents;
              if (documents.length == 0) {
                result = await db
                    .collection('chats')
                    .where('contact2', isEqualTo: widget.prefs.getString('uid'))
                    .where('contact1', isEqualTo: doc["uid"])
                    .getDocuments();
                documents = result.documents;
                if (documents.length == 0) {
                  await db.collection('chats').add({
                    'contact1': widget.prefs.getString('uid'),
                    'contact2': doc["uid"]
                  }).then((documentReference) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          prefs: widget.prefs,
                          chatId: documentReference.documentID,
                          title: doc["name"],
                        ),
                      ),
                    );
                  }).catchError((e) {});
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        prefs: widget.prefs,
                        chatId: documents[0].documentID,
                        title: doc["name"],
                      ),
                    ),
                  );
                }
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      prefs: widget.prefs,
                      chatId: documents[0].documentID,
                      title: doc["name"],
                    ),
                  ),
                );
              }
            },
          ),
        )
        .toList();
  }

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

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      switch (_currentIndex) {
        case 0:
          _tabTitle = "Contacts";
          break;
        case 1:
          _tabTitle = "Profile";
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _children = [
      generateContactTab(),
      generateProfileTab(),
    ];
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(_tabTitle),
            actions: <Widget>[
              (_currentIndex == 0
                  ? Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            openContacts();
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.backspace),
                          onPressed: () {
                            FirebaseAuth.instance.signOut().then((response) {
                              widget.prefs.remove('is_verified');
                              widget.prefs.remove('mobile_number');
                              widget.prefs.remove('uid');
                              widget.prefs.remove('name');
                              widget.prefs.remove('profile_photo');
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      RegistrationPage(prefs: widget.prefs),
                                ),
                              );
                            });
                          },
                        )
                      ],
                    )
                  : Container())
            ],
          ),
          body: _children[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            onTap: onTabTapped, // new
            currentIndex: _currentIndex, // new
            items: [
              new BottomNavigationBarItem(
                icon: Icon(Icons.mail),
                title: Text('Contacts'),
              ),
              new BottomNavigationBarItem(
                icon: Icon(Icons.verified_user),
                title: Text('Profile'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
