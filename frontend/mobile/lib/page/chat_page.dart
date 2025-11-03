import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:getwork_app/service/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String _peerUid = '';
  String _peerName = '';
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;
  bool _isAtBottom = true; // track whether the user is viewing the bottom of the list
  bool _initialLoaded = false;

  // Use AuthService to determine the current logged-in user uid (DB user_id as string)
  String get currentUid => AuthService.userId.value ?? '1';
  String get currentUsername => AuthService.username.value ?? '';

  String get backendBase {
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:4000';
    } catch (_) {}
    return 'http://localhost:4000';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null) {
      _peerUid = (args['uid'] ?? '').toString();
      _peerName = (args['name'] ?? '').toString();
    }
    _start();
  }

  void _start() {
    _loadMessages();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _loadMessages());
    // listen to scroll events to detect whether user scrolled up
    _scrollController.addListener(() {
      try {
        if (!_scrollController.hasClients) return;
        final max = _scrollController.position.maxScrollExtent;
        final off = _scrollController.offset;
        // consider "at bottom" when within 80 pixels of bottom
        final atBottom = (max - off) < 80;
        _isAtBottom = atBottom;
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addLocalMessage(Map<String, dynamic> msg, {bool scroll = true}) {
    try {
      // mark as local/optimistic so we can reconcile with server results later
      final m = Map<String, dynamic>.from(msg);
      m['_local'] = true;
      setState(() {
        _messages = List<Map<String, dynamic>>.from(_messages)..add(m);
      });
      if (scroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
            }
          } catch (_) {}
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    if (_peerUid.isEmpty) return setState(() => _loading = false);
    final bool firstLoad = !_initialLoaded;
    if (firstLoad) setState(() { _loading = true; });
    try {
      final uri = Uri.parse('$backendBase/chat/messages?uid=$currentUid&peer=${Uri.encodeComponent(_peerUid)}&limit=200');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        // Accept either array or { data: [...] }
        final list = body is List ? body : (body['data'] is List ? body['data'] : []);
        final rawList = (list as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

        // Normalize messages to a consistent shape so UI logic is simple
        String normalizeUrl(String u) {
          try {
            final s = u.trim();
            if (s.startsWith('http://') || s.startsWith('https://')) return s;
            if (s.startsWith('/')) return '$backendBase$s';
            // if it's already a host:port form, return as-is, otherwise prefix
            if (s.contains('://')) return s;
            return '$backendBase/$s';
          } catch (_) {
            return u;
          }
        }

        List<Map<String, dynamic>> mapped = rawList.map((raw) {
          // get sender uid
          String senderUid = '';
          String senderName = '';
          try {
            final s = raw['sender'];
            if (s is Map) {
              // CometChat often nests the user under sender.entity
              // e.g. sender: { entity: { uid: '1', name: 'foo', avatar: '...' }, entityType: 'user' }
              if (s['entity'] is Map) {
                final ent = Map<String, dynamic>.from(s['entity']);
                senderUid = (ent['uid'] ?? ent['id'] ?? ent['user_id'])?.toString() ?? '';
                senderName = (ent['name'] ?? ent['username'] ?? ent['displayname'])?.toString() ?? '';
              }
              // fallback to top-level sender fields if present
              if (senderUid.isEmpty) {
                senderUid = (s['uid'] ?? s['id'] ?? s['user_id'])?.toString() ?? '';
              }
              if (senderName.isEmpty) {
                senderName = (s['name'] ?? s['username'] ?? s['displayname'])?.toString() ?? '';
              }
            } else if (s is String) {
              senderUid = s;
            }
          } catch (_) {}
          senderUid = senderUid.isNotEmpty ? senderUid : (raw['senderUid']?.toString() ?? raw['sender_id']?.toString() ?? raw['senderId']?.toString() ?? raw['from']?.toString() ?? '');
          senderName = senderName.isNotEmpty ? senderName : (raw['senderName']?.toString() ?? raw['senderName']?.toString() ?? raw['sender_username']?.toString() ?? raw['fromName']?.toString() ?? '');

          // message type and content
          String type = (raw['type'] ?? raw['message_type'])?.toString() ?? '';
          final data = raw['data'] is Map ? Map<String, dynamic>.from(raw['data']) : <String, dynamic>{};
          if (type.isEmpty) {
            if (data['attachments'] is List && (data['attachments'] as List).isNotEmpty) type = 'image';
            else type = 'text';
          }

          String text = raw['text']?.toString() ?? data['text']?.toString() ?? raw['message']?.toString() ?? '';
          List attachments = [];
          try {
            if (data['attachments'] is List) attachments = List.from(data['attachments']);
            else if (raw['attachments'] is List) attachments = List.from(raw['attachments']);
          } catch (_) {}
          String imageUrl = '';
          if (attachments.isNotEmpty) {
            imageUrl = attachments[0]['url']?.toString() ?? attachments[0]['file']?.toString() ?? '';
            if (imageUrl.isNotEmpty) {
              // normalize attachment entry so UI reads a usable absolute url
              try { attachments[0] = Map<String, dynamic>.from(attachments[0]); } catch (_) {}
            }
          }
          if (imageUrl.isEmpty) imageUrl = raw['url']?.toString() ?? data['url']?.toString() ?? '';
          if ((imageUrl ?? '').isNotEmpty) {
            imageUrl = normalizeUrl(imageUrl);
            // if attachments present, ensure the first attachment url is normalized too
            if (attachments.isNotEmpty) {
              try { attachments[0] = Map<String, dynamic>.from(attachments[0]); } catch (_) {}
              try { attachments[0]['url'] = imageUrl; } catch (_) {}
            }
          }
          final caption = data['caption']?.toString() ?? raw['caption']?.toString() ?? '';

          // createdAt normalization
          String createdAt = raw['createdAt']?.toString() ?? raw['created_at']?.toString() ?? raw['sentAt']?.toString() ?? raw['sent_at']?.toString() ?? raw['timestamp']?.toString() ?? '';
          // stable id extraction (CometChat may provide id or data.id)
          String msgId = '';
          try {
            msgId = (raw['id'] ?? raw['message_id'] ?? raw['msg_id'] ?? raw['data']?['id'] ?? raw['data']?['message_id'] ?? '')?.toString() ?? '';
            if (msgId == '') {
              // sometimes nested under data or top-level 'metadata' etc
              msgId = (raw['metadata']?['id'] ?? '')?.toString() ?? '';
            }
          } catch (_) { msgId = ''; }

          return {
            'raw': raw,
            'id': msgId,
            'senderUid': senderUid,
            'senderName': senderName,
            'type': type,
            'text': text,
            'attachments': attachments,
            'url': imageUrl,
            'caption': caption,
            'createdAt': createdAt,
          };
        }).toList();

        // sort by createdAt (oldest first). Support ISO strings, unix seconds, or millis.
        int parseEpochMs(dynamic v) {
          try {
            if (v == null) return 0;
            final s = v.toString();
            if (s.isEmpty) return 0;
            // numeric? determine seconds vs millis
            final n = num.tryParse(s);
            if (n != null) {
              // heuristics: <= 1e10 => seconds, >1e10 => millis
              final nn = n.toDouble();
              if (nn.abs() < 1e10) return (nn * 1000).toInt();
              return nn.toInt();
            }
            // try parse ISO
            final dt = DateTime.tryParse(s);
            if (dt != null) return dt.millisecondsSinceEpoch;
            return 0;
          } catch (_) { return 0; }
        }

        mapped.sort((a, b) {
          final A = parseEpochMs(a['createdAt']);
          final B = parseEpochMs(b['createdAt']);
          return A.compareTo(B);
        });

        // Preserve any optimistic local messages (marked with _local) so they don't disappear
        List<Map<String, dynamic>> localOptimistic = [];
        try {
          localOptimistic = List<Map<String, dynamic>>.from(_messages.where((e) => e['_local'] == true));
        } catch (_) { localOptimistic = []; }

        List<Map<String, dynamic>> merged = List<Map<String, dynamic>>.from(mapped);

        bool isSame(Map a, Map b) {
          try {
            final at = (a['type'] ?? '')?.toString() ?? '';
            final bt = (b['type'] ?? '')?.toString() ?? '';
            final aSender = (a['senderUid'] ?? a['sender'] ?? '')?.toString() ?? '';
            final bSender = (b['senderUid'] ?? b['sender'] ?? '')?.toString() ?? '';
            if (at == 'image' || bt == 'image') {
              final aurl = (a['url'] ?? (a['attachments'] is List && a['attachments'].isNotEmpty ? a['attachments'][0]['url'] : '') ?? '')?.toString() ?? '';
              final burl = (b['url'] ?? (b['attachments'] is List && b['attachments'].isNotEmpty ? b['attachments'][0]['url'] : '') ?? '')?.toString() ?? '';
              if (aurl.isNotEmpty && burl.isNotEmpty) return aurl == burl && aSender == bSender;
            }
            // text match: same sender and same text
            final atext = (a['text'] ?? '')?.toString() ?? '';
            final btext = (b['text'] ?? '')?.toString() ?? '';
            if (atext.isNotEmpty && btext.isNotEmpty) return atext == btext && aSender == bSender;
          } catch (_) {}
          return false;
        }

        for (final local in localOptimistic) {
          final exists = merged.any((m) => isSame(local, m));
          if (!exists) merged.add(local);
        }

        // debug: print fetched count and last message summary (only in debug builds)
        try {
          final fetchedCount = merged.length;
          final last = fetchedCount > 0 ? merged.last : null;
          // Keep debug output minimal: only count and lastId. Avoid printing message text to terminal.
          /*if (kDebugMode) {
            debugPrint('CHAT FETCH count=$fetchedCount lastId=${last != null ? last['id'] ?? '-' : '-'}');
          }*/
        } catch (_) {}

        // apply merged messages to state
        setState(() { _messages = merged; });
        // scroll to bottom only when user is already at/near bottom or on initial load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (!_scrollController.hasClients) return;
            if (!_initialLoaded || _isAtBottom) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
            _initialLoaded = true;
          } catch (_) {}
        });
      }
    } catch (e) {
      // ignore
    } finally {
      // only clear the global loading indicator if it was shown for the first load
      if (firstLoad) setState(() { _loading = false; });
    }
  }

  Future<void> _sendText() async {
    final txt = _textController.text.trim();
    if (txt.isEmpty || _peerUid.isEmpty) return;
    _textController.clear();
    // optimistic local append so user sees the message immediately
    final local = {
      'raw': {},
      'senderUid': currentUid,
      'senderName': currentUsername,
      'type': 'text',
      'text': txt,
      'attachments': [],
      'url': '',
      'caption': '',
      // use epoch-ms numeric string for consistent sorting
      'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    _addLocalMessage(local);

    final payload = {
      'senderUid': currentUid,
      'senderName': currentUsername,
      'receiver': _peerUid,
      'receiverType': 'user',
      'text': txt,
    };
    try {
      final resp = await http.post(Uri.parse('$backendBase/chat/messages/text-as-user'), headers: {'content-type': 'application/json'}, body: jsonEncode(payload));
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // refresh to reconcile with server state
        await _loadMessages();
      } else {
        // show error and optionally mark message as failed (not implemented)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ส่งข้อความไม่สำเร็จ (code ${resp.statusCode})')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาดขณะส่งข้อความ')));
    }
  }

  Future<void> _sendImageByUrl(String url, {String? caption}) async {
    if (url.trim().isEmpty || _peerUid.isEmpty) return;
    final payload = {
      'senderUid': currentUid,
      'senderName': currentUsername,
      'receiver': _peerUid,
      'receiverType': 'user',
      'url': url.trim(),
      'caption': caption ?? ''
    };
    try {
      final resp = await http.post(Uri.parse('$backendBase/chat/messages/image-url'), headers: {'content-type': 'application/json'}, body: jsonEncode(payload));
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _loadMessages();
      }
    } catch (e) {}
  }

  void _promptImageUrl() async {
    final controller = TextEditingController();
    final captionController = TextEditingController();
    final ok = await showDialog<bool?>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('ส่งรูป (URL)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Image URL')),
            TextField(controller: captionController, decoration: const InputDecoration(labelText: 'Caption (optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('ส่ง')),
        ],
      );
    });
    if (ok == true) {
      final url = controller.text.trim();
      final caption = captionController.text.trim();
      await _sendImageByUrl(url, caption: caption.isEmpty ? null : caption);
    }
  }

  Future<void> _pickAndUploadImage() async {
    // Pick image from gallery and upload to server, then send as chat image
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, maxHeight: 1600, imageQuality: 80);
      if (picked == null) return;

      // Send to chat file-upload endpoint so server will forward to CometChat
      final uri = Uri.parse('$backendBase/chat/messages/image');
      final req = http.MultipartRequest('POST', uri);
      // required form fields for the chat endpoint
      req.fields['senderUid'] = currentUid;
      req.fields['receiver'] = _peerUid;
      req.fields['receiverType'] = 'user';
      req.fields['caption'] = '';
      req.files.add(await http.MultipartFile.fromPath('image', picked.path, filename: p.basename(picked.path)));

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);
      // debug log
      print('CHAT UPLOAD RESP status=${resp.statusCode} body=${resp.body}');

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        final sample = resp.body != null && resp.body.toString().length > 200 ? '${resp.body.toString().substring(0,200)}...' : resp.body;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('การอัปโหลดรูปล้มเหลว (code ${resp.statusCode})\n$sample')));
        return;
      }

      // Parse server response and use returned URL (avoid composing backendBase + path)
      try {
        final decoded = jsonDecode(resp.body);
        String? returnedUrl;
        if (decoded is Map && decoded['url'] is String) {
          returnedUrl = decoded['url'] as String;
        } else if (decoded is Map && decoded['image'] is String) {
          final img = decoded['image'] as String;
          if (img.startsWith('http://') || img.startsWith('https://')) returnedUrl = img;
          else if (img.startsWith('/')) returnedUrl = '$backendBase$img';
          else returnedUrl = '$backendBase/$img';
        }
        print('UPLOAD returnedUrl=$returnedUrl body=${resp.body}');
        // optimistic local show of the image message
        if (returnedUrl != null && returnedUrl.isNotEmpty) {
          final localImg = {
            'raw': {},
            'senderUid': currentUid,
            'senderName': currentUsername,
            'type': 'image',
            'text': '',
            'attachments': [ {'url': returnedUrl} ],
            'url': returnedUrl,
            'caption': '',
            // use epoch-ms numeric string for consistent sorting
            'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          };
          _addLocalMessage(localImg);
        }
      } catch (_) {
        print('UPLOAD response (non-json): ${resp.body}');
      }

      // Refresh messages (server already forwarded the image to CometChat)
      await _loadMessages();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งรูปเรียบร้อย')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เกิดข้อผิดพลาดขณะเลือก/อัปโหลดรูป')));
    }
  }

  Widget _buildBubble(Map<String, dynamic> m) {
    final isMe = (m['senderUid']?.toString() ?? '').trim() == currentUid;
    final text = m['text']?.toString() ?? '';
    final type = (m['type']?.toString() ?? 'text');
    final createdAt = m['createdAt']?.toString() ?? '';
    final senderName = m['senderName']?.toString() ?? '';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF3A5A99) : const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (type == 'image') ...[
                if ((m['attachments'] as List?)?.isNotEmpty ?? false) ...[
                  (() {
                    String src = '';
                    try {
                      final att0 = (m['attachments'] as List)[0];
                      if (att0 is String) src = att0;
                      else if (att0 is Map) src = (att0['url'] ?? att0['file'] ?? att0['uri'] ?? '')?.toString() ?? '';
                    } catch (_) {
                      // ignore
                    }
                    if ((src ?? '').isEmpty) {
                      try { src = (m['url'] ?? '').toString(); } catch (_) { src = ''; }
                    }
                    if (src.isEmpty) return const SizedBox.shrink();
                    return Image.network(
                      src,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 40, color: Colors.black26),
                      ),
                    );
                  })()
                ] else if ((m['url'] ?? '').toString().isNotEmpty)
                  Image.network(
                    (m['url'] ?? '').toString(),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 40, color: Colors.black26),
                    ),
                  )
              else
                const SizedBox.shrink(),
              if ((m['caption'] ?? '').toString().isNotEmpty) SizedBox(height: 6),
              if ((m['caption'] ?? '').toString().isNotEmpty) Text((m['caption'] ?? '').toString(), style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
            ] else ...[
              Text(text.toString(), style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
            ],
            if (!isMe && senderName.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(senderName, style: TextStyle(fontSize: 11, color: Colors.black45)),
            ],
            if (createdAt != null) SizedBox(height: 6),
            if (createdAt != null) Text(createdAt.toString(), style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : Colors.black45)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF19506B),
          title: Row(children: [
            const BackButton(color: Colors.white),
            const SizedBox(width: 6),
            Expanded(child: Text(_peerName.isNotEmpty ? _peerName : 'แชท')),
          ]),
        ),
        body: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        return _buildBubble(m);
                      },
                    ),
            ),
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                color: Colors.white,
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.photo), onPressed: _pickAndUploadImage),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendText(),
                        decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'พิมพ์ข้อความ...'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _sendText, child: const Text('ส่ง'))
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

