import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Nim',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Nim'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  void play(int np, int ms, int mind, int maxd) {
    GamePage gp = new GamePage(np,ms,mind, maxd);
    Navigator.of(context).push(new MaterialPageRoute<void>(builder: ((context) => gp)));

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: new Column(children: <Widget>[
          new RaisedButton(onPressed: ()=>play(1, 1,5,15), child: new Text("Level 1")),
          new RaisedButton(onPressed: ()=>play(1, 4,5,20), child: new Text("Level 2")),
          new RaisedButton(onPressed: ()=>play(2,-1,5,15), child: new Text("Level 3")),
          new RaisedButton(onPressed: ()=>play(2, 3,5,15), child: new Text("Level 4")),
          new RaisedButton(onPressed: ()=>play(3,-1,1,10), child: new Text("Level 5")),
          new RaisedButton(onPressed: ()=>play(3, 4,1,10), child: new Text("Level 6")),
        ],));

  }
}

class GamePage extends StatefulWidget {
  GamePage(this.numPiles, this.maxSub, this.minDraw, this.maxDraw, {Key key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  final int numPiles;
  final int maxSub;
  final int minDraw;
  final int maxDraw;

  String title() {
    if(this.maxSub>0)
      return "Nim: Subtract up to "+maxSub.toString();
    else
      return "Nim: Subtract as much as you want";
  }


  @override
  _GamePageState createState() => new _GamePageState(this.numPiles, this.maxSub, this.minDraw, this.maxDraw);
}

class _GamePageState extends State<GamePage> {
  final int numPiles;
  final int maxSub;
  final int minDraw;
  final int maxDraw;
  List<int> history;
  List<int> curVals;
  ScrollController sc;
  int active=-1;
  Random rand;
  String message;
  bool firstTurn=true;

  _GamePageState(this.numPiles, this.maxSub, this.minDraw, this.maxDraw)  {
    rand=Random.secure();
    sc=new ScrollController();
    restartGameInternal();
  }

  void sub(int i) {
    setState(() {
      curVals[i]--;
      active=i;
    });
  }

  void add(int i) {
    setState(() {
      curVals[i]++;
      if(curVals[i]==history[i])
        active=-1;
    });
  }

  void autoPlay() {
    int resid=0;
    int modulus = maxSub+1;
    if(maxSub==-1)
      modulus=1000;
    for(int v in curVals)
      resid^=v%modulus;
    if(resid==0) {
      int total=0;
      for(int v in curVals)
        total+=min(v, modulus-1);
      int r = rand.nextInt(total);
      for(int vi=0; vi<curVals.length; vi++) {
        int untouchable=max(0,curVals[vi]-modulus+1);
        if(r<curVals[vi]-untouchable) {
          curVals[vi]=r+untouchable;
          return;
        }
        else {
          r-=(curVals[vi]-untouchable);
        }
      }
    }
    else {
      for(int vi=0; vi<numPiles; vi++) {
        int mod = curVals[vi]%modulus;
        int mod2=mod^resid;
        if(mod2 < mod) {
          curVals[vi] += mod2 - mod;
          return;
        }
      }
    }
  }

  void play() {
    bool finished=false;
    setState( () {
      firstTurn=false;
      List<int> hist2=List.from(curVals);
      hist2.addAll(history);
      history=hist2;
      active = -1;
      sc.jumpTo(0);
      if(curVals.reduce(max)==0) {
        message="You win!";
        finished=true;
      }
    });
    if(!finished)
      playOpp();
  }

  void playOpp() {
    firstTurn=false;
    setState( () {
      autoPlay();
      List<int> hist2 = List.from(curVals);
      hist2.addAll(history);
      history = hist2;
      active = -1;
      if (curVals.reduce(max) == 0) {
        message = "You lose!";
        return;
      }
      sc.jumpTo(0);
    });
  }

  void restartGameInternal() {
    message=null;
    history=[];
    for(int i=0; i<numPiles; i++) {
      int nv = rand.nextInt(maxDraw-numPiles-minDraw+2)+minDraw;
      for(int h in history) {
        if(nv>=h) nv++;
      }
      history.add(nv);
      history.sort();
    }
    curVals=List.from(history);
    active=-1;
    firstTurn=true;
  }

  void restartGameAction() {
    setState(() => restartGameInternal());
  }

  void reset() {
    setState( () {
      for(int vi=0; vi<numPiles; vi++)
        {
          curVals[vi]=history[vi];
        }
        active=-1;
    });
  }

  @override
  Widget build(BuildContext context) {
    TextStyle style = new TextStyle(fontSize: 20.0);
    TextStyle style2 = new TextStyle(fontSize: 20.0, color: Colors.red);

    List<Widget> childList = [];

    List<Widget> gridChildren=[];
    for(int vi =0; vi<numPiles; vi++) {
      int v=curVals[vi];
      bool isActive=(active==-1) || (active==vi);
      bool canSub=isActive && v>0 && (history[vi]-v!=maxSub);
      bool canAdd=active==vi;
      gridChildren.add(new Row(children: <Widget>[
        new Expanded(child:new Container()),
        new IconButton(icon: new Icon(Icons.remove), onPressed: canSub? (()=>sub(vi)) : null),
        new Text(v.toString(), style: style,),
        new IconButton(icon: new Icon(Icons.add), onPressed: canAdd? (()=>add(vi)) : null),
        new Expanded(child:new Container()),
      ]));
    }
    for(int hi=0; hi<history.length; hi++) {
      int h=history[hi];
      int rowNum=hi~/numPiles;
      TextStyle currentStyle = (rowNum%2==0) ? style2 : style;
        gridChildren.add(new Row(children: <Widget>[
          new Expanded(child:new Container()),
          new Text(h.toString(), style: currentStyle,),
          new Expanded(child:new Container()),
        ]));
    }
    if(message!=null) {
      childList.add(new Text(message, style:style));
    }
    childList.add(new Flexible(child:new GridView.count(
      crossAxisCount: numPiles,
      children: gridChildren,
      childAspectRatio: 15/numPiles,
      controller: sc,
      reverse: true,)));
    Widget lastButton;
    if(firstTurn)
      lastButton = new RaisedButton(child: new Text("Pass"), onPressed: active==-1 ? playOpp : null,);
    else
      lastButton =new RaisedButton(child: new Text("Restart Game"), onPressed: restartGameAction,);
    childList.add(new ButtonBar(children: <Widget>[
      new RaisedButton(child: new Text("Reset Turn"), onPressed: active==-1? null : reset),
      new RaisedButton(child: new Text("Done"), onPressed: active==-1? null :play),
      lastButton
    ]));

    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title()),
        ),
        body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(children: childList)));
  }
}
