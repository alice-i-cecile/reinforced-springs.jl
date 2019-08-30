
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'engine.dart';

class ContraptionParameters with ChangeNotifier {
  var points = <Offset>[];
  var lines = Set();

  void blank(){
    points = <Offset>[];
    lines = Set();

    notifyListeners();
  }

  void node(position) {
    points.add(position);

    notifyListeners();
  }

  void spring(int node1, int node2){
    lines.add([node1, node2]);

    notifyListeners();
  }

  void delete(Set<int> selected){
    // TODO: selection changes when points are deleted
    var newPoints = <Offset>[];

    for (int i = 0; i < points.length; i++){
      if (!selected.contains(i)){
        newPoints.add(points[i]);
      }
    }
    points = newPoints;

    var newLines = Set();
    for (var line in lines){
      if (!(selected.contains(line[0]) || 
            selected.contains(line[1]))){
        newLines.add(line);
      }
    } 

    lines = newLines;

    notifyListeners();
  }

  // TODO: vary mirror based on selected nodes
  void mirror(){
    double center = 200.0;
    
    for (int i = 0; i < points.length; i++){
      // Distance between center and initial position is c - x
      // Distance between center and final position must be the same
      // Thus c + (c-x) gives the final position
      points[i] = Offset(2*center - points[i].dx, points[i].dy);
    }

    notifyListeners();
  }

  // TODO: vary rotate based on selected nodes
  void rotate(angle){
    double cx = 200.0;
    double cy = 200.0;
    
    for (int i = 0; i < points.length; i++){
      double dx = points[i].dx;
      double dy = points[i].dy;

      double rx = cos(angle) * (dx - cx) - sin(angle) * (dy - cy) + cx;
      double ry = sin(angle) * (dx - cx) + cos(angle) * (dy - cy) + cy;

      points[i] = Offset(rx, ry);
    }

    notifyListeners();
  }

  void connect(Set<int> selected){
    for (int i in selected){
      for (int j in selected){
        if (i > j){
          lines.add([i, j]);
        }
      }
    }

    notifyListeners();
  }

  void disconnect(Set<int> selected){
    var newLines = Set();
    
    for (var line in lines){
      if (!(selected.contains(line[0]) && 
            selected.contains(line[1]))){
            newLines.add(line);
          }
    }

    lines = newLines;

    notifyListeners();
  }

  void translate(Offset position, Set<int> selected){
    double width = 400.0;
    double height = 400.0;

    int n = selected.length;
    double sumX = 0.0;
    double sumY = 0.0;
    for (int i = 0; i < points.length; i++){
      if (selected.contains(i)){
        sumX += points[i].dx;
        sumY += points[i].dy;
      }
    }

    var center = [sumX/n, sumY/n];
    var shift = [position.dx - center[0], position.dy - center[1]];

    for (int i = 0; i < points.length; i++){
      if (selected.contains(i)){
        double newX = points[i].dx + shift[0];
        double newY = points[i].dy + shift[1];

        if (newX < 0) {
          newX = 0;
        } else if (newX > width){
          newX = width;
        }

        if (newY < 0) {
          newY = 0;
        } else if (newY > height){
          newY = height;
        }

        points[i] = Offset(newX, newY);
      }
    }

    notifyListeners();
  }
}

class ContraptionState with ChangeNotifier{
  var points = <Offset>[];
  var lines = Set();
  var velocity = [];

  // TODO: get appropriate context
  var context;

  //var environment = Provider.of<Environment>(context);
  //var contraptionParameters = Provider.of<ContraptionParameters>(context);

  void reset(){
    this.pause();

    //points = contraptionParameters.points;
    //lines = contraptionParameters.lines;
    //velocity = [[0.0, 0.0] for int i in 1:points.length];

    notifyListeners();
  }

  void play(){
    // Start a timer that repeats itself

    //var newState = engine(environment, contraptionParameters, this);
    //points = newState['points'];
    //velocity = newState['velocity'];

    notifyListeners();
  }

  void pause(){

  }
}

class Environment with ChangeNotifier{
  double gravity = 10;
  double drag = 0.01;
  double elasticity = 0.1;
}