import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:timeago/timeago.dart' as timeago;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive Trending Posts',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TrendingPostsPage(),
    );
  }
}

class TrendingPostsPage extends StatefulWidget {
  @override
  _TrendingPostsPageState createState() => _TrendingPostsPageState();
}

class _TrendingPostsPageState extends State<TrendingPostsPage> {
  List<dynamic> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final url = Uri.parse('https://api.hive.blog/');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        "id": 1,
        "jsonrpc": "2.0",
        "method": "bridge.get_ranked_posts",
        "params": {"sort": "trending", "tag": "", "observer": "hive.blog"}
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        posts = data['result'];
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load posts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All posts'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double padding = screenWidth * 0.02;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final createdTime = DateTime.parse(post['created']);
              final thumbnail = post['json_metadata'] != null &&
                  post['json_metadata']['image'] != null &&
                  post['json_metadata']['image'].isNotEmpty
                  ? post['json_metadata']['image'][0]
                  : null;

              // Adjust styles based on screen width
              double fontSize = screenWidth > 800
                  ? 18
                  : screenWidth > 400
                  ? 14
                  : 12; // Adjust for desktop, tablet, and mobile
              double imageSize = screenWidth > 800
                  ? 120
                  : screenWidth > 400
                  ? 80
                  : 60;

              return Card(
                margin: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top bar with responsive layout
                    Container(
                      color: Colors.grey[200],
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: padding / 2,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Text(
                              post['author'] ?? 'No Author',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: fontSize,
                              ),
                            ),
                            SizedBox(width: padding),
                            Text(
                              "(${post['children'] ?? 0})",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: fontSize * 0.9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: padding),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: padding,
                                vertical: padding / 2,
                              ),
                              child: Text(
                                '${post['author_role'] ?? 'Guest'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  fontSize: fontSize * 0.9,
                                ),
                              ),
                            ),
                            SizedBox(width: padding),
                            Text(
                              post['community_title'] ?? 'No Community',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: fontSize * 0.9,
                              ),
                            ),
                            SizedBox(width: padding),
                            Text(
                              timeago.format(createdTime),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: fontSize * 0.9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Main content
                    ListTile(
                      leading: thumbnail != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0), // Adds rounded corners
                        child: Image.network(
                          thumbnail,
                          width: constraints.maxWidth * 0.2, // Set width to 20% of available width
                          height: constraints.maxWidth * 0.2, // Set height to 20% of available width
                          fit: BoxFit.cover, // Ensures the image maintains its aspect ratio
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback if the image fails to load
                            return Icon(Icons.broken_image, size: constraints.maxWidth * 0.2, color: Colors.grey);
                          },
                        ),
                      )
                          : Icon(Icons.image, size: constraints.maxWidth * 0.2, color: Colors.grey),

                      title: Text(
                        post['title'] ?? 'No Title',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: fontSize,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (post['body'] != null &&
                                post['body'].length > 100)
                                ? post['body'].substring(0, 100) + '...'
                                : post['body'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: fontSize * 0.9,
                            ),
                          ),
                          SizedBox(height: padding / 2),
                          Row(
                            children: [
                              Icon(Icons.thumb_up,
                                  size: fontSize * 1.2,
                                  color: Colors.grey),
                              SizedBox(width: padding / 2),
                              Text(
                                  '${post['active_votes'] != null ? post['active_votes'].length : 0}'),
                              SizedBox(width: padding),
                              Icon(Icons.comment,
                                  size: fontSize * 1.2,
                                  color: Colors.grey),
                              SizedBox(width: padding / 2),
                              Text('${post['children']}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
