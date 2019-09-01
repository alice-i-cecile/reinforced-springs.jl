import 'package:provider/provider.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';

import 'package:flutter/material.dart';

import 'contraption.dart';

// STATE
class Tool with ChangeNotifier{
  String selectedTool = 'Node';

  void changeTool(String toolName){
    selectedTool = toolName;

    notifyListeners();
  }
}

class Selection with ChangeNotifier{
  Set<int> selectedNodes = Set();

  void clearSelection(){
    selectedNodes = Set();

    notifyListeners();
  }

  void select(nodeNum){
    // Select if new, deselect otherwise
    if (!selectedNodes.contains(nodeNum)){
      selectedNodes.add(nodeNum);
    } else {
      selectedNodes.remove(nodeNum);
    }

    notifyListeners();
  }
}

// Interaction
void buildGesture(ContraptionParameters contraption, Offset position, String tool, Selection selection){
  double distance(aX, aY, bX, bY){
    double d = (aX - bX)*(aX - bX) + 
               (aY - bY)*(aY - bY);
    return d;
  }

  switch(tool) {
    case 'Node': {
      contraption.node(position);
      break;
    }
    case 'Spring': {
      if (contraption.nodes.length >= 2){
        var nodes = contraption.nodes;
        double first = distance(nodes[0][0], nodes[0][1], position.dx, position.dy);
        double second = distance(nodes[1][0], nodes[1][1], position.dx, position.dy);
        int node1 = 0;
        int node2 = 1;

        // Node1 is always the closest node found
        if (first > second){
          var temp = first;
          first = second;
          second = temp;

          var tempNode = node1;
          node1 = node2;
          node2 = tempNode;
        }

        for (int i = 1; i < nodes.length; i++){
          double current = distance(nodes[i][0], nodes[i][1], position.dx, position.dy);
          if (current < second){
            if (current < first){
              second = first;
              node2 = node1;

              first = current;
              node1 = i;
            } else {
              second = current;
              node2 = i;
            }
          }
        } 

        contraption.spring(node1, node2);
      }

      break;
    }
    case 'Select': {
      if (contraption.nodes.length >= 1){
        var nodes = contraption.nodes;
            
        // Find nearest node to tapped position
        double min = distance(nodes[0][0], nodes[0][1], position.dx, position.dy);
        int nodeNum = 0;

        for (int i = 1; i < nodes.length; i++){
          double current = distance(nodes[i][0], nodes[i][1], position.dx, position.dy);
          if (current < min){
            nodeNum = i;
            min = current;
          }
        } 

        //selection.selectedNodes.add(nodeNum);
        selection.select(nodeNum);    
      }

      break;
    }
    case 'Transform': {
      contraption.translate(position, selection.selectedNodes);
      break;
    }
  }

}

// TAB
class BuildTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          BuildInterface(), 
          BuildDisplay()],
      )
    );
  }
}

// INTERFACE
class BuildInterface extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return(
      Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          BuildProperties(),
          Row(children: <Widget>[
            BuildTools(),
            BuildComponents()
          ]),
          Consumer<Tool>(
            builder: (context, tool, child) => Text('Tool: ${tool.selectedTool}')
          )
        ]
      )
    );
  }
}

class PropertyInput extends StatefulWidget{

  final String fieldName;
  final double minValue;
  final double initialValue;
  final double maxValue;
  final updateFunction;
  
  const PropertyInput({Key key, this.fieldName, this.minValue, this.initialValue, this.maxValue, this.updateFunction}): super(key: key);

  @override
  _PropertyInputState createState() => _PropertyInputState();
}

class _PropertyInputState extends State<PropertyInput>{
  String numValidator(String input){
    if (input == null){
      return widget.initialValue.toString();
    }

    double x = double.tryParse(input);
    if (x == null){
      return widget.initialValue.toString();
    }

    if (x < widget.minValue){
      return widget.minValue.toString();
    } else if (x > widget.maxValue){
      return widget.maxValue.toString();
    } else {
      return x.toString();
    }
  }

  @override
  Widget build(BuildContext context){
    return(
      Container(child:
        TextFormField(
          decoration: InputDecoration(
            labelText: widget.fieldName,
          ),
          initialValue: widget.initialValue.toString(),
          keyboardType: TextInputType.number, 
          validator: numValidator, 
          textAlign: TextAlign.right,
          onSaved: (String input) => widget.updateFunction(double.parse(input))
        ),
        width: 150
      ) 
    );
  }
}

class BuildProperties extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    var contraptionParameters = Provider.of<ContraptionParameters>(context);
    var environment = Provider.of<Environment>(context);
    var selection =  Provider.of<Selection>(context);

    return(
      Column(children: <Widget>[
        PropertyInput(
          fieldName: 'Mass', 
          minValue: 0.01,
          initialValue: contraptionParameters.defaultMass,
          maxValue: 100.0,
          updateFunction: (newMass) => contraptionParameters.editMass(selection.selectedNodes, newMass)
        ),
        PropertyInput(
          fieldName: 'Spring Strength', 
          minValue: 0.0,
          initialValue: contraptionParameters.defaultStrength,
          maxValue: 100.0,
          updateFunction: (newStrength) => contraptionParameters.editMass(selection.selectedNodes, newStrength)
        ),
        PropertyInput(
          fieldName: 'Rest Length', 
          minValue: 0.01,
          initialValue: 1.0,
          maxValue: 100.0,
          updateFunction: (scale) => contraptionParameters.editRestLength(selection.selectedNodes, scale)
        ),
        PropertyInput(
          fieldName: 'Gravity', 
          minValue: -100.0,
          initialValue: environment.gravity,
          maxValue: 100.0,
          updateFunction: (newGravity) => environment.setGravity(newGravity)
        ),
        PropertyInput(
          fieldName: 'Elasticity', 
          minValue: 0.0,
          initialValue: environment.elasticity, 
          maxValue: 1.0,
          updateFunction: (newElasticity) => environment.setElasticity(newElasticity)
        ),
        PropertyInput(
          fieldName: 'Drag', 
          minValue: 0.0,
          initialValue: environment.drag,
          maxValue: 1.0,
          updateFunction: (newDrag) => environment.setDrag(newDrag)
        )
      ])
    );
  }
}

class BuildTools extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return(
      Column(children: <Widget>[
        Row(children: <Widget>[
          IconButton(                
            icon: const Icon(Icons.near_me),
            tooltip: 'Select',
            onPressed: () => Provider.of<Tool>(context, listen: false).changeTool('Select'),
          ),
          IconButton(                
            icon: const Icon(Icons.close),
            tooltip: 'Clear Selection',
            onPressed: () => Provider.of<Selection>(context, listen: false).clearSelection(),
          ),
          Consumer<Selection>(
            builder: (context, selection, child) => IconButton(                
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
              onPressed: (){
                Provider.of<ContraptionParameters>(context, listen: false).delete(selection.selectedNodes);
                selection.clearSelection();
              }
            ),
          )
        ]),
        Row(children: <Widget>[
          Consumer<Selection>(
            builder: (context, selection, child) => IconButton(
              icon: const Icon(Icons.rotate_left),
              tooltip: 'Rotate Counterclockwise',
              onPressed: () => Provider.of<ContraptionParameters>(context, listen: false).rotate(-3.14159/6.0, selection.selectedNodes)
            )
          ),
          Consumer<Selection>(
            builder: (context, selection, child) => IconButton(
              icon: const Icon(Icons.rotate_right),
              tooltip: 'Rotate Clockwise',
              onPressed: () => Provider.of<ContraptionParameters>(context, listen: false).rotate(3.14159/6.0, selection.selectedNodes)
            )
          ),
          Consumer<Selection>(
            builder: (context, selection, child) => IconButton(
              icon: const Icon(Icons.flip),
              tooltip: 'Mirror Horizontally',
              onPressed: () => Provider.of<ContraptionParameters>(context, listen: false).mirror(selection.selectedNodes, 'horizontal')
            )
          ),
          Consumer<Selection>(
            builder: (context, selection, child) => IconButton(
              icon: Transform.rotate(angle: 3.14159/2, child:const Icon(Icons.flip)),
              tooltip: 'Mirror Vertically',
              onPressed: () => Provider.of<ContraptionParameters>(context, listen: false).mirror(selection.selectedNodes, 'vertical')
            )
          ),
        ]),
        Row(children: <Widget>[
          Consumer<Selection>(
            builder: (context, selection, child) => IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Connect',
              onPressed: () => Provider.of<ContraptionParameters>(context, listen: false).connect(selection.selectedNodes)
            ),
          ),
          Consumer<Selection>(
            builder: (context, selection, child) => IconButton(
              icon: const Icon(Icons.scatter_plot),
              tooltip: 'Disconnect',
              onPressed: () => Provider.of<ContraptionParameters>(context, listen: false).disconnect(selection.selectedNodes)
            ),
          ),
          IconButton(
            icon: const Icon(Icons.transform),
            tooltip: 'Transform',
            onPressed: () => Provider.of<Tool>(context, listen: false).changeTool('Transform')
          ),
        ]),
        Row(children: <Widget>[
          IconButton(                
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: (){},
          ),
          IconButton(                
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: (){},
          )
        ]),
      ])
    );
  }
}

// TODO: add regular polygons
class BuildComponents extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        RaisedButton(
          onPressed: () => Provider.of<Tool>(context, listen: false).changeTool('Node'),
          child: Text('Node')),
        RaisedButton(
          onPressed: () => Provider.of<Tool>(context, listen: false).changeTool('Spring'),
          child: Text('Spring'))
      ],
    );
  }
}

// DISPLAY
class BuildDisplay extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    var contraption = Provider.of<ContraptionParameters>(context, listen: false);
    var selected = Provider.of<Selection>(context, listen: false);

    return CustomPaint(
      painter: BuildPainter(contraption, selected),
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          border: Border.all(width: 2),
        ),
        child: Consumer<Tool>(
          builder: (context, tool, child) => Consumer<Selection>(
            builder: (context, selection, child) => PositionedTapDetector(
              onTap: (position) => buildGesture(contraption, position.relative, tool.selectedTool, selection)
            )
          )
        )
      )
    );
  }
}

class BuildPainter extends CustomPainter {
  ContraptionParameters contraptionParameters;
  Selection selection;

  BuildPainter(ContraptionParameters contraptionParameters, Selection selection) : super(repaint: Listenable.merge([contraptionParameters, selection])) {
    this.contraptionParameters = contraptionParameters;
    this.selection = selection;
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    double pointRadius = 3.0;
    var pointPaint = Paint();
    var selectPaint = Paint();

    var linePaint = Paint();

    var selected = selection.selectedNodes;

    for (int i = 0; i < contraptionParameters.nodes.length; i++){
      var point = contraptionParameters.nodes[i];
      
      if (selected.contains(i)) {
        canvas.drawCircle(Offset(point[0], point[1]), 1.5 * pointRadius, selectPaint);
      } else {
        canvas.drawCircle(Offset(point[0], point[1]), pointRadius, pointPaint);
      }
    }

    for (var line in contraptionParameters.connections){
      double x0 = contraptionParameters.nodes[line[0]][0];
      double y0 = contraptionParameters.nodes[line[0]][1];

      double x1 =  contraptionParameters.nodes[line[1]][0];
      double y1 = contraptionParameters.nodes[line[1]][1];

      canvas.drawLine(Offset(x0, y0), Offset(x1, y1), linePaint); 
    }
  }

  @override
  bool shouldRepaint(BuildPainter oldDelegate) => true;
}