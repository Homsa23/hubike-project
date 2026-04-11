import 'package:flutter/material.dart';

class InboxPage extends StatelessWidget {
  const InboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      
      body:
       ListView(
        padding: const EdgeInsets.all(16.0),
        children:[
          
          Text(
            "Messages",
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20),

          ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(0xFF4CAF50), // Hubike Green
              child: Icon(Icons.directions_bike, color: Colors.white),
            ),
            title: Text("Welcome to HUBIKE!"),
            subtitle: Text("Ready for your first ride in Annaba?"),
            trailing: Text("10:00 AM", style: TextStyle(
              color: Colors.grey,
              fontSize: 12
              )
            ),
          ),
          Divider(),

          
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.receipt, color: Colors.white),
            ),
            title: Text("Ride Receipt"),
            subtitle: Text("Your 45-minute ride has ended. Tap to view details."),
            trailing: Text("Mon", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}