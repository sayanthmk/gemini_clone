import 'dart:io';
import 'dart:typed_data';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiuser = ChatUser(
      id: "1",
      firstName: "Gemini",
      profileImage:
          "https://studiovisual.com.br/wp-content/uploads/2024/04/Gemini-1.jpg");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue,
                Colors.purple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: const Text(
              "Gemini",
              style: TextStyle(fontSize: 30, color: Colors.white),
            ),
            elevation: 0,
          ),
        ),
      ),
      body: _buildui(),
    );
  }

  Widget _buildui() {
    return DashChat(
        inputOptions: InputOptions(
          trailing: [
            IconButton(
                onPressed: _sendmediamessage, icon: const Icon(Icons.image))
          ],
        ),
        currentUser: currentUser,
        onSend: sendmessage,
        messages: messages);
  }

  void sendmessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String question = chatMessage.text;
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [File(chatMessage.medias!.first.url).readAsBytesSync()];
      }
      gemini.streamGenerateContent(question, images: images).listen((event) {
        ChatMessage? lastmessage = messages.firstOrNull;
        if (lastmessage != null && lastmessage.user == geminiuser) {
          lastmessage = messages.removeAt(0);
          String response = event.content?.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          lastmessage.text += response;
          setState(() {
            messages = [lastmessage!, ...messages];
          });
        } else {
          String response = event.content?.parts?.fold(
                  "", (previous, current) => "$previous ${current.text}") ??
              "";
          ChatMessage message = ChatMessage(
              user: geminiuser, createdAt: DateTime.now(), text: response);
          setState(() {
            messages = [message, ...messages];
          });
        }
      });
    } catch (e) {
      print(e);
    }
  }

  void _sendmediamessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
          user: currentUser,
          createdAt: DateTime.now(),
          text: "Describe This picture",
          medias: [
            ChatMedia(url: file.path, fileName: "", type: MediaType.image)
          ]);
      sendmessage(chatMessage);
    }
  }
}
