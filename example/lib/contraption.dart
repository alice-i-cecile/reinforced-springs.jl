
import 'package:flutter/material.dart';
import 'package:quiver/core.dart';
import 'dart:math';
import 'dart:async';

import 'engine.dart';

boundsSanitize(double x, double y){
  double width = 400.0;
  double height = 400.0;

  if (x < 0){
    x = 0;
  } else if (x > width){
    x = width;
  }

  if (y < 0){
    y = 0;
  } else if (y > height){
    y = height;
  }

  return [x, y];
}

class SpringIndex {
  int i;
  int j;

  SpringIndex(int i, int j){
    if (i > j){
      this.i = i;
      this.j = j;
    } else {
      this.i = j;
      this.j = i;
    }
  }

  bool operator ==(o) => o.i == this.i && o.j == this.j;
  int get hashCode => hash2(i.hashCode, j.hashCode);

}

class ContraptionParameters with ChangeNotifier {
  int nodeNum = 0;
  var nodes = Map();
  var connections = Set();

  double defaultMass = 1.0;
  double defaultStrength = 1.0;

  var mass = Map();
  var radius = Map();

  var strength = Map();
  var springWidth = Map();
  var restLength = Map();
  
  void blank(selection){
    nodes = Map();
    connections = Set();

    defaultMass = 1.0;
    defaultStrength = 1.0;

    mass = Map();
    radius = Map();

    strength = Map();
    springWidth = Map();
    restLength = Map();

    selection.clearSelection();

    notifyListeners();
  }

  ContraptionParameters copy(Set<int> selected){
    var clipboard = ContraptionParameters();

    if (selected.length > 0){
      var center = [0.0, 0.0];

      for (int i  in selected){
        center[0] += nodes[i][0];
        center[1] += nodes[i][1];
      }

      center[0] = center[0]/selected.length;
      center[1] = center[1]/selected.length;

      for (int i in selected){
        clipboard.nodes[i] = ([nodes[i][0] - center[0],
                               nodes[i][1] - center[1]]);
        clipboard.mass[i] = mass[i];
        clipboard.radius[i] = radius[i];
      }

      for (var connection in connections){
        int i = connection[0];
        int j = connection[1];
        if (selected.contains(i) && selected.contains(j)){
          clipboard.connections.add([i,j]);
          clipboard.strength[SpringIndex(i,j)] = strength[SpringIndex(i,j)];
          clipboard.springWidth[SpringIndex(i,j)] = springWidth[SpringIndex(i,j)];
          clipboard.restLength[SpringIndex(i,j)] = restLength[SpringIndex(i,j)];
        }
      }
    }

    return clipboard;
  }

  void paste(ContraptionParameters clipboard, Offset position){
    var cToP = Map();

    for (int i in clipboard.nodes.keys){
      cToP[i] = nodeNum;
      
      var p = boundsSanitize(
        clipboard.nodes[i][0] + position.dx,
        clipboard.nodes[i][1] + position.dy
      );
      node(p[0], p[1]);
      mass[nodeNum] = clipboard.mass[i];
      radius[nodeNum] = clipboard.radius[i];
    }

    for (var connection in clipboard.connections){
      int i = connection[0];
      int j = connection[1];
      int parentI = cToP[i];
      int parentJ = cToP[j];

      var keyC = SpringIndex(i,j);
      var keyP = SpringIndex(parentI, parentJ);

      connections.add([parentI, parentJ]);
      strength[keyP] = clipboard.strength[keyC];
      springWidth[keyP] = clipboard.springWidth[keyC];
      restLength[keyP] = clipboard.restLength[keyC];
    }

    notifyListeners();
  }

  double dist(int node1, int node2){
    double x1 = nodes[node1][0];
    double x2 = nodes[node2][0];
    double y1 = nodes[node1][1];
    double y2 = nodes[node2][1];

    double d = sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2));
    return d;
  }

  double distSquared(int node1, int node2){
    double x1 = nodes[node1][0];
    double x2 = nodes[node2][0];
    double y1 = nodes[node1][1];
    double y2 = nodes[node2][1];

    double d2 = (x1-x2)*(x1-x2) + (y1-y2)*(y1-y2);
    return d2;
  }

  int nearest(double x, double y){
    double distance(aX, aY, bX, bY){
      double d = (aX - bX)*(aX - bX) + 
                 (aY - bY)*(aY - bY);
      return d;
    }

    // Find nearest node to tapped position
    double min = distance(nodes[0][0], nodes[0][1], x, y);
    int nodeNum = 0;

    for (int i in nodes.keys){
      double current = distance(nodes[i][0], nodes[i][1], x, y);
      if (current < min){
        nodeNum = i;
        min = current;
      }
    } 

    return nodeNum;
  }

  void setMass(int node, double newMass){
    double pointRadius = 3.0;

    mass[node] = newMass;
    radius[node] = pow(newMass, 0.333) * pointRadius;

    notifyListeners();
  }

  void setStrength(int node1, int node2, double newStrength){
    strength[SpringIndex(node1, node2)] = newStrength;
    springWidth[SpringIndex(node1, node2)] = sqrt(newStrength) * 2.0;

    notifyListeners();
  }

  void setRestLength(int node1, int node2, double newRestLength){
    restLength[SpringIndex(node1, node2)] = newRestLength;

    notifyListeners();
  }

  void editMass(Set<int> selection, double newMass){
    if (selection.length == 0){
      for (int i in nodes.keys){
        setMass(i, newMass);
      }
    } else {
      for (int i in selection){
        setMass(i, newMass);
      }
    }
    
    notifyListeners();
  }

  void editStrength(Set<int> selection, double newStrength){
    if (selection.length == 0){
      for (var connection in connections){
        setStrength(connection[0], connection[1], newStrength);
      }
    } else {
      for (var connection in connections){
        int i = connection[0];
        int j = connection[1];
        if (selection.contains(i) && selection.contains(j)){
          setStrength(i, j, newStrength);
        }
      }
    }
    
    notifyListeners();
  }

  void editRestLength(Set<int> selection, double scale){
    if (selection.length == 0){
      for (var connection in connections){
        int i = connection[0];
        int j = connection[1];
        double newRestLength = scale * dist(i, j);
        setRestLength(connection[0], connection[1], newRestLength);
      }
    } else {
      for (var connection in connections){
        int i = connection[0];
        int j = connection[1];
        if (selection.contains(i) && selection.contains(j)){
          int i = connection[0];
          int j = connection[1];
          double newRestLength = scale * dist(i, j);
          setRestLength(connection[0], connection[1], newRestLength);        
        }
      }
    }
    
    notifyListeners();
  }

  void node(double x, double y) {
    nodes[nodeNum] = [x, y];
    setMass(nodeNum, defaultMass);
    nodeNum += 1;

    notifyListeners();
  }

  void spring(int node1, int node2){
    // node1 must be greater than node 2
    // Prevents double and self connections 
    if (node1 < node2){
      connections.add([node2, node1]);
      setStrength(node2, node1, defaultStrength);
      setRestLength(node2, node1, dist(node2, node1));
    } else if (node1 > node2){
      connections.add([node1, node2]);
      setStrength(node1, node2, defaultStrength);
      setRestLength(node1, node2, dist(node1, node2));
    }

    notifyListeners();
  }

  void delete(Set<int> selected){
    if (selected.length > 0){
      for (int i in selected){
        nodes.remove(i);
        mass.remove(i);
        radius.remove(i);
      }

      for (var connection in connections){
        connection.remove(connection);
        strength.remove(connection);
        springWidth.remove(connection);
        restLength.remove(connection);
      }

      selected = Set();

      notifyListeners();
    }
  }

  void mirror(Set<int> selected, String direction){    
    if (direction == 'horizontal'){
      double sumX = 0.0;
      int n = selected.length;

      if (selected.length == 0){
        n = nodes.length;
        for (int i in nodes.keys){
          sumX += nodes[i][0];
        }
      } else {
        for (int i in nodes.keys){
          if (selected.contains(i)){
            sumX += nodes[i][0];
          }
        }
      }

      double center = sumX/n;
      
      for (int i in nodes.keys){
        // Distance between center and initial position is c - x
        // Distance between center and final position must be the same
        // Thus c + (c-x) gives the final position
        if (selected.length == 0 || selected.contains(i)){
          double newX = 2*center - nodes[i][0];
          
          nodes[i] = boundsSanitize(newX, nodes[i][1]);
        }
      }
    } else if (direction == 'vertical'){
      double sumY = 0.0;
      int n = selected.length;

      if (selected.length == 0){
        n = nodes.length;
        for (int i in nodes.keys){
          sumY += nodes[i][1];
        }
      } else {
        for (int i in nodes.keys){
          if (selected.contains(i)){
            sumY += nodes[i][1];
          }
        }
      }

      double center = sumY/n;
      
      for (int i in nodes.keys){
        // Distance between center and initial position is c - x
        // Distance between center and final position must be the same
        // Thus c + (c-x) gives the final position
        if (selected.length == 0 || selected.contains(i)){
          double newY = 2*center - nodes[i][1];
          
          nodes[i] = boundsSanitize(nodes[i][0], newY);
        }
      }
    }

    notifyListeners();
  }

  void rotate(angle, Set<int> selected){
    double sumX = 0.0;
    double sumY = 0.0;
    int n = selected.length;

    if (selected.length == 0){
      n = nodes.length;
      for (int i in nodes.keys){
        sumX += nodes[i][0];
        sumY += nodes[i][1];
      }
    } else {
      for (int i in nodes.keys){
        if (selected.contains(i)){
          sumX += nodes[i][0];
          sumY += nodes[i][1];
        }
      }
    }

    double cx = sumX/n;
    double cy = sumY/n;
    
    for (int i in nodes.keys){
      if (selected.length == 0 || selected.contains(i)){
        double dx = nodes[i][0];
        double dy = nodes[i][1];

        double rx = cos(angle) * (dx - cx) - sin(angle) * (dy - cy) + cx;
        double ry = sin(angle) * (dx - cx) + cos(angle) * (dy - cy) + cy;

        nodes[i] = boundsSanitize(rx, ry);
      }
    }

    notifyListeners();
  }

  void connect(Set<int> selected){
    if (selected.length == 0){
      for (int i in nodes.keys){
        for (int j in nodes.keys){
          if (i > j){
            spring(i, j);
          }
        }
      }
    } else {
      for (int i in selected){
        for (int j in selected){
          if (i > j){
            spring(i,j);
          }
        }
      }
    }

    notifyListeners();
  }

  void disconnect(Set<int> selected){
    if (selected.length == 0){
      connections = Set();
    } else {
      var newConnections = Set();
      
      for (var connection in connections){
        if (!(selected.contains(connection[0]) && 
              selected.contains(connection[1]))){
              newConnections.add(connection);
            }
      }

      connections = newConnections;
    }

    for (int i  in selected){
      for (int j in selected){
        strength.remove(SpringIndex(i,j));
        springWidth.remove(SpringIndex(i,j));
        restLength.remove(SpringIndex(i,j));
      }
    }

    notifyListeners();
  }

  void translate(Offset position, Set<int> selected){
    int n = selected.length;
    if (n == 0){
      n = nodes.length;
    }

    double sumX = 0.0;
    double sumY = 0.0;
    for (int i in nodes.keys){
      if (selected.contains(i) || selected.length == 0){
        sumX += nodes[i][0];
        sumY += nodes[i][1];
      }
    }

    var center = [sumX/n, sumY/n];
    var shift = [position.dx - center[0], position.dy - center[1]];

    for (int i in nodes.keys){
      if (selected.contains(i) || selected.length == 0){
        double newX = nodes[i][0] + shift[0];
        double newY = nodes[i][1] + shift[1];

        nodes[i] = boundsSanitize(newX, newY);
      }
    }

    for (var connection in connections){
      int i = connection[0];
      int j = connection[1];
      if (selected.contains(i) || selected.contains(j)){
        restLength[SpringIndex(i,j)] = dist(i, j);
      }
    }

    notifyListeners();
  }

  void scale(Offset position1, Offset position2, Set<int> selected){
    double xMin = 400.0;
    double xMax = 0.0;
    double yMin = 400.0;
    double yMax = 0.0;

    for (int i in selected){
      double x = nodes[i][0];
      double y = nodes[i][1];

      if (x < xMin){
        xMin = x;
      }

      if (x > xMax){
        xMax = x;
      }

      if (y < yMin){
        yMin = y;
      }

      if (y > yMax){
        yMax = y;
      }
    }

    double scaleX = (position1.dx - position2.dx).abs() / (xMax - xMin);
    double scaleY = (position1.dy - position2.dy).abs() / (yMax - yMin);

    for (int i in nodes.keys){
      if (selected.contains(i) || selected.length == 0){
        double newX = (nodes[i][0] - xMin)*scaleX + xMin;
        double newY = (nodes[i][1] - yMin)*scaleY + yMin;

        nodes[i] = boundsSanitize(newX, newY);
      }
    }

    for (var connection in connections){
      int i = connection[0];
      int j = connection[1];
      if (selected.contains(i) || selected.contains(j)){
        restLength[SpringIndex(i,j)] = dist(i, j);
      }
    }

    notifyListeners();
  }

  void align(Set<int> selected, String direction){
    int d = (direction == 'horizontal') ? 1 : 0;
    
    double center = 0.0;
    for (int i in selected){
      center += nodes[i][d];
    }
    center = center / selected.length;

    for (int i in selected){
      nodes[i][d] = center;
    }

    for (var connection in connections){
      int i = connection[0];
      int j = connection[1];
      if (selected.contains(i) || selected.contains(j)){
        restLength[SpringIndex(i,j)] = dist(i, j);
      }
    }

    notifyListeners();
  }

  void distribute(Set<int> selected, String direction){
    if (selected.length > 1){
      int d = (direction == 'horizontal') ? 0 : 1;
      int n = selected.length;
      double min = 400.0;
      double max = 0.0;

      for (int i in selected) {
        if (nodes[i][d] < min){
          min = nodes[i][d];
        }

        if (nodes[i][d] > max){
          max = nodes[i][d];
        }
      }
      print(min);
      print(max);

      // Sort points by coordinate
      // Then assign them in order to spaced points
      var sorted =  selected.toList();
      sorted.sort((a, b) => nodes[a][d].compareTo(nodes[b][d]));
      
      for (int i = 0; i < n; i++){
        nodes[sorted[i]][d] = min + (i / (n-1)) * (max - min);
      }

      for (var connection in connections){
        int i = connection[0];
        int j = connection[1];
        if (selected.contains(i) || selected.contains(j)){
          restLength[SpringIndex(i,j)] = dist(i, j);
        }
      }

      notifyListeners();
    }
  }

}

class ContraptionState with ChangeNotifier{
  var points = Map();
  var velocity = Map();
  var lines = Set();

  var gameClock;

  @override 
  void dispose(){
    super.dispose();
    gameClock.cancel();
  }

  double dist(point1, point2){
    double x1 = points[point1][0];
    double x2 = points[point2][0];
    double y1 = points[point1][1];
    double y2 = points[point2][1];

    double d = sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2));
    return d;
  }

  void reset(ContraptionParameters contraptionParameters){
    if (gameClock != null){
      this.pause();
    }

    points = Map.from(contraptionParameters.nodes);
    lines = Set.from(contraptionParameters.connections);

    for (int k in points.keys){
      velocity[k] = [0.0, 0.0];
    }

    notifyListeners();
  }

  void play(Environment environment, ContraptionParameters contraptionParameters, Input input){
    int timeStep = 50;
    Timer.periodic(Duration(milliseconds: timeStep),
    (timer){
      gameClock = timer;
      simulate(environment, contraptionParameters, input, timeStep.toDouble()/1000);
    });
  }

  void simulate(Environment environment, ContraptionParameters contraptionParameters, Input input, double timeStep){
    if (velocity.length != 0){
      var newState = engine(environment, contraptionParameters, this, input, timeStep);
      this.points = newState['points'];
      this.velocity = newState['velocity'];

      notifyListeners();
    }
  }

  void pause(){
    gameClock.cancel();

    notifyListeners();
  }
}

class Environment with ChangeNotifier{
  double gravity = 10;
  double elasticity = 0.8;
  double drag = 0.01;

  void setGravity(double newGravity){
    gravity = newGravity;

    notifyListeners();
  }

  void setElasticity(double newElasticity){
    elasticity = newElasticity;

    notifyListeners();
  }

  void setDrag(double newDrag){
    drag = newDrag;

    notifyListeners();
  }
}

class Input with ChangeNotifier{
  double inputForce = 10.0;
  bool up = false;
  bool down = false;
  bool left = false;
  bool right = false;

  void update(field, value){
    field = value;
    notifyListeners();
  }
}