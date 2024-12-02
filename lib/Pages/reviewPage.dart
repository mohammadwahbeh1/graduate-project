import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

const String ip = "192.168.1.8";

class ReviewPage extends StatefulWidget {
  final String terminalId;

  ReviewPage({required this.terminalId});

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  double _rating = 3.0;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      String? token = await storage.read(key: 'jwt_token');

      if (token != null) {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        currentUserId = decodedToken['id'].toString();

        final response = await http.get(
          Uri.parse('http://$ip:3000/api/v1/reviews/${widget.terminalId}'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          setState(() {
            reviews = List<Map<String, dynamic>>.from(data['reviews']
                .map((review) =>
            {
              "id": review["review_id"],
              "comment": review["comment"],
              "rating": review["rating"],
              "created_at": review["created_at"],
              "username": review["username"],
              "user_id": review["user_id"],
            }));
            isLoading = false;
          });
        } else {
          throw Exception(
              'Failed to load reviews. Status Code: ${response.statusCode}');
        }
      } else {
        throw Exception('Token is null');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addReview() async {
    try {
      String? token = await storage.read(key: 'jwt_token');

      if (token != null) {
        final response = await http.post(
          Uri.parse('http://$ip:3000/api/v1/reviews/add'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'terminal_id': widget.terminalId,
            'comment': _commentController.text,
            'rating': _rating,
          }),
        );

        if (response.statusCode == 201) {
          fetchReviews();
          _commentController.clear();
          _rating = 3.0;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review added successfully!')),
          );
        } else {
          throw Exception(
              'Failed to add review. Status Code: ${response.statusCode}');
        }
      } else {
        throw Exception('Token is null');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding review')),
      );
    }
  }

  Future<void> deleteReview(String reviewId) async {
    try {
      String? token = await storage.read(key: 'jwt_token');

      if (token != null) {
        final response = await http.delete(
          Uri.parse('http://$ip:3000/api/v1/reviews/delete/$reviewId'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          fetchReviews();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review deleted successfully!')),
          );
        } else {
          throw Exception(
              'Failed to delete review. Status Code: ${response.statusCode}');
        }
      } else {
        throw Exception('Token is null');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting review')),
      );
    }
  }

  Future<void> editReview(String reviewId, String currentComment) async {
    _commentController.text = currentComment;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          //Edit Review
          title: const Text(
          'Edit Review',
          style: TextStyle(
            color:  Colors.amber,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        )
          ,

          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Edit your comment',
                  labelStyle: TextStyle(color: Colors.teal),

                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                itemSize: 30,
                allowHalfRating: false,
                itemCount: 5,
                itemBuilder: (context, _) =>
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
            ],
          ),
          actions: [

            TextButton(
              onPressed: () async {
                String? token = await storage.read(key: 'jwt_token');
                if (token != null) {
                  final response = await http.put(
                    Uri.parse('http://$ip:3000/api/v1/reviews/update/$reviewId'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'comment': _commentController.text,
                      'rating': _rating,
                    }),
                  );
                  if (response.statusCode == 200) {
                    fetchReviews();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review updated successfully!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error updating review')),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 4,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Save Changes'),
            ),


            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget buildReviewCard(Map<String, dynamic> review) {
    bool isUserReview = review['user_id'].toString() == currentUserId.toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: isUserReview
          ? Slidable(
        key: ValueKey(review['id']),
        startActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (_) =>
                  editReview(review['id'].toString(), review['comment']),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'edit',
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => deleteReview(review['id'].toString()),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: BorderRadius.circular(10),
            ),
          ],
        ),
        child: buildReviewContent(review),
      )
          : buildReviewContent(review),
    );
  }

  Widget buildReviewContent(Map<String, dynamic> review) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundImage: AssetImage('assets/commenter-1.jpg'),
                radius: 30,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['username'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: review['rating'].toDouble(),
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 18.0,
                          direction: Axis.horizontal,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          review['created_at'],
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
          const SizedBox(height: 8),
          Text(
            review['comment'],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text(
          'Reviews',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        elevation: 4,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          return buildReviewCard(reviews[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Add Review',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        labelText: 'Write your comment',
                        labelStyle: const TextStyle(color: Colors.teal),
                        // Custom label color
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          // Rounded corners
                          borderSide: const BorderSide(color: Colors.amber, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.amber, width: 2),
                        ),
                      ),
                      maxLines: 3,
                      style: const TextStyle(fontSize: 16),
                      keyboardType: TextInputType.text, // دعم الإيموجي
                    ),
                    const SizedBox(height: 16),
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      itemSize: 30,
                      allowHalfRating: false,
                      itemCount: 5,
                      itemBuilder: (context, _) =>
                      const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: addReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('Submit'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Colors.amber,
        child: const Icon(
          Icons.add,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}