import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:my_app/widgets/chat_bubble.dart';
import 'package:image_picker/image_picker.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final Uint8List? imageBytes; 
  
  ChatMessage({required this.text, required this.isUser, this.imageBytes});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

const String _apiKey = "AIzaSyBA0ftfz3NTJ0QV-UGnh9QaEm-tM_27-ic";

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash', // A fast and capable model for chat
    apiKey: _apiKey,
  );
  late ChatSession _chat;
  bool _isLoading = false;

  // New: State to hold selected image data for multimodal query
  Uint8List? _selectedImageBytes;
  final String _imageMimeType = 'image/jpeg'; // Assuming JPEG for the placeholder

  @override
  void initState() {
    super.initState();
    // Initialize a chat session for multi-turn conversation
    _startNewChat();
  }

    void _startNewChat() {
     // Initialize a chat session for multi-turn conversation
    _chat = _model.startChat();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

   Future<void> _pickImage() async {
    // If an image is already selected, clear it
    if (_selectedImageBytes != null) {
      setState(() {
        _selectedImageBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image cleared.')),
      );
      return;
    }
    
try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) { 
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          // You should try to dynamically determine the MIME type of the selected image.
          // For simplicity, we stick to 'image/jpeg' here.
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected! Type your question and hit send.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Check if both text and image are empty
    if ((text.isEmpty && _selectedImageBytes == null) || _isLoading) return;

    // 1. Add User Message and Clear Input
    setState(() {
      _messages.add(ChatMessage(
        text: text.isEmpty ? 'Image sent.' : text, 
        isUser: true,
        imageBytes: _selectedImageBytes, // Include image in user message display
      ));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();
    final List<Part> parts = [];
    if (_selectedImageBytes != null) {
      // The API expects the image as bytes with its MIME type
      parts.add(DataPart(_imageMimeType, _selectedImageBytes!));
    }
    parts.add(TextPart(text));

    final sentImageBytes = _selectedImageBytes; // Store for local use
    setState(() {
      _selectedImageBytes = null;
    });

    try {
      // 2. Send message to the chat session (this preserves history)
      final response = await _chat.sendMessage(Content('user', parts));
      
      // 3. Add AI Response
      setState(() {
        _messages.add(ChatMessage(
          text: response.text ?? 'Error: No response received.',
          isUser: false,
        ));
        _isLoading = false;
      });
    } catch (e) {
      // 4. Handle Errors
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: Could not connect to AI. Check your API key or network. ($e)',
          isUser: false,
        ));
        _isLoading = false;
      });
      print('Gemini API Error: $e');
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {

    final hintText = _selectedImageBytes != null 
      ? 'Describe the image...' 
      : 'Ask Flutter AI anything...';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter AI Chat'),
        centerTitle: true,
        actions: [
          // New: Clear Chat History Button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Start new chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _selectedImageBytes = null;
                _textController.clear();
                _startNewChat();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 10, bottom: 8),
                child: TypingIndicator(),
              ),
            ),
          
          Padding(
            padding: EdgeInsets.only(
              bottom: 8,
              left: 10,
              right: 10,
              top: 8,
            ),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    _selectedImageBytes != null ? Icons.image_search : Icons.image,
                    color: _selectedImageBytes != null ? const Color(0xFF4A148C) : Colors.grey[700],
                  ),
                  onPressed: _pickImage,
                  tooltip: _selectedImageBytes != null ? 'Clear Image' : 'Select Image',
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: const Color(0xFF673AB7), // Deep Purple FAB
                  mini: true,
                  shape: const CircleBorder(),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
