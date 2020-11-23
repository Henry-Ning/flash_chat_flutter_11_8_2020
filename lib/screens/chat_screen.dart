import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;
//12:40 Lec 196 Angela uses a FirebaseUser class but thats changed to just User class
User loggedInUser;

class ChatScreen extends StatefulWidget {
  static String id =
      'chat_screen'; // for route, we make this static so we can access this from main
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String messageText;

  @override
  void initState() {
    // TODO: implement initState
    getCurrentUser();
    super.initState();
  }

  void getCurrentUser() {
    final user = _auth
        .currentUser; //11:53 Lecture 196 angela provides currentUser() its deprecated and removed
    try {
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  // void messageStream() async {
  //   await for (var snapshot in _firestore.collection('messages').snapshots()) {
  //     for (var message in snapshot.docs) {
  //       var messegeData = message.data();
  //       var messageSender = messegeData['sender'];
  //       var messageText = messegeData['text'];
  //       print(
  //           'this is messege sender $messageSender and this is message text $messageText');
  //     }
  //   }
  // }
  //
  // void getMessages() async {
  //   var user = _firestore.collection('messages');
  //   var message = await user.get();
  //   for (int x = 0; x < message.docs.length; x++) {
  //     Map<String, dynamic> data = message.docs[x].data();
  //     print('${data['sender']} \n  ${data['text']} \n\n');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //getMessages();
                //messageStream();
                _auth.signOut();
                Navigator.pop(context);
                //Implement logout functionality
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(
              firestore: _firestore,
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value; //Do something with the user input.
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () async {
                      messageTextController.clear();
                      try {
                        var status =
                            await _firestore.collection('messages').add({
                          'text': messageText,
                          'sender': loggedInUser.email,
                        });
                        print(status);
                      } catch (e) {
                        print(e);
                      }
                      //Implement send functionality.
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  final firestore;
  MessageStream({@required this.firestore});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('messages').snapshots(),
      builder: (context, snapshot) {
        List<MessageBubble> messageWidgets = [];
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data.docs
            .reversed; //we reversed this because the messages were coming on the top of the List Widget instead of at the bottom,
        for (var message in messages) {
          final messageData = message.data();
          final messageText = messageData['text'];
          final messageSender = messageData['sender'];
          final currentUser = loggedInUser.email;
          var isMe = true;
          (currentUser == messageSender) ? isMe = true : isMe = false;
          final messageWidget = MessageBubble(
            messageSender: messageSender,
            messageText: messageText,
            isMe: isMe,
          );

          messageWidgets.add(messageWidget);
        }
        return Expanded(
          child: ListView(
            reverse:
                true, //to get the list view to keep scrolling to the bottom as new messages came in
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageWidgets,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String messageSender;
  final String messageText;
  final bool isMe;

  MessageBubble({this.messageSender, this.messageText, this.isMe});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            (isMe) ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(3.0),
            child: Text(
              '$messageSender',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.black54,
              ),
            ),
          ),
          Material(
            elevation: 5.0,
            borderRadius: (isMe)
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0)),
            color: (isMe) ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                '$messageText',
                style: TextStyle(
                  fontSize: 18,
                  color: (isMe) ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
