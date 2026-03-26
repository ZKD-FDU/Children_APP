import 'package:flutter/material.dart';
import '../models/user.dart';
import '../widgets/chat_bubble.dart';
import '../utils/navigation_helper.dart';
import '../utils/sensitive_word_checker.dart';
import '../widgets/screen_time_banner.dart';

class ChatPage extends StatefulWidget {
  ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final TextEditingController _inputController;

  // 假数据：消息列表（保持原有 Demo 展示逻辑，不在此追加）
  final List<Map<String, dynamic>> _messages = [
    {
      'message': '你好！你想一起踢足球吗？',
      'isMe': false,
      'time': '10:30',
    },
    {
      'message': '好啊！什么时候？',
      'isMe': true,
      'time': '10:32',
    },
    {
      'message': '周六下午怎么样？在公园里！',
      'isMe': false,
      'time': '10:33',
    },
    {
      'message': '太好了！我让我妈妈同意一下！',
      'isMe': true,
      'time': '10:35',
    },
    {
      'message': '好的，等你消息！😊',
      'isMe': false,
      'time': '10:36',
    },
  ];

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;

    final result = SensitiveWordChecker.check(text);
    if (result.hasRisk) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('安全提醒'),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('返回修改'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('发送成功（演示）')),
    );
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final User? friend = ModalRoute.of(context)?.settings.arguments as User?;
    final String friendName = friend?.name ?? '好友';
    final String friendAvatar =
        friend?.avatar ?? 'assets/images/avatar1.png'; // asset
    const String myAvatar = 'assets/images/avatar1.png'; // asset

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.purple[200],
              backgroundImage: NetworkImage(friendAvatar),
            ),
            const SizedBox(width: 12),
            Text(
              friendName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.purple[400],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 智能返回：如果有 arguments（从好友列表进入），则 pop；否则切换到首页
            NavigationHelper.smartPop(context, defaultRoute: '/home');
          },
        ),
      ),
      body: Column(
        children: [
          const ScreenTimeBanner(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ChatBubble(
                  message: msg['message'] as String,
                  isMe: msg['isMe'] as bool,
                  avatar: msg['isMe'] as bool ? myAvatar : friendAvatar,
                );
              },
            ),
          ),
          // 输入框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        hintText: '输入消息...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.purple[400],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _handleSend,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationHelper.buildBottomNav(
        context,
        1,
        selectedColor: Colors.orange[400],
      ),
    );
  }
}
