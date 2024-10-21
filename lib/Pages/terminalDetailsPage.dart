import 'package:flutter/material.dart';

class TerminalDetailsPage extends StatelessWidget {
  final String terminalName; // Terminal name passed from homePage
  final String terminalId;


  TerminalDetailsPage({required this.terminalName,required this.terminalId});



  @override
  Widget build(BuildContext context) {
    print(terminalId);
    return Scaffold(
      appBar: AppBar(
        title: Text(terminalName+" Terminal ",

          style: TextStyle(fontWeight: FontWeight.w500),



        ),
        centerTitle: true,
        backgroundColor: Colors.yellow,


      ),
      body: Center(
        child: Text(
          'Details for $terminalName',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
