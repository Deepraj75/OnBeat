import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:fl_chart/fl_chart.dart';


Future<void> main() async
{
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const HomePage()
  ));
}


class HomePage extends StatelessWidget
{
  const HomePage({super.key});

  @override
  Widget build (BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text("OnBeat",
        style: TextStyle(
          fontWeight: FontWeight.bold
        )),
      ),
      body: RC());
  }
}


class RC extends StatefulWidget
{
  const RC({super.key});

  @override
  RCState createState() => RCState();
}

class RCState extends State<RC>
{
  final soloud = SoLoud.instance;
  late AudioSource sound;
  final record = AudioRecorder();
  Timer? timer;
  String? path;
  bool isRunning = false;
  double bpm = 135;
  int count = 4;
  int beats = 0;


  @override
  void initState()
  {
    super.initState();
    initSound();
  }


  Future<void> initSound() async
  {
    await soloud.init();
    sound = await 
    soloud.loadAsset('assets/short_click.wav');
  }


  Future<void> play() async
  {
    isRunning = true;
    timer = Timer.periodic(
      Duration(seconds: 1),
      (timer)
      {
        if (count == 0)
        {
          setState(()
          {
          timer.cancel();
          checkRhythm();
          });
        }
        else
        {
          setState(() 
          =>count--);
        }
      });
  }


  Future<void> checkRhythm() async
  {
    int len = (60000/bpm).round();
    timer = Timer.periodic(
      Duration(milliseconds:len),(timer)
    {
      if (beats == 4)
      {
        timer.cancel();
        //
        beats = 0;
      }
      else
      {
        playSound();
        ++beats;
      }
    }
    );

    if (await record.hasPermission())
    {
      final dir = await getApplicationDocumentsDirectory();
      path = '${dir.path}/recording.wav';
      const config = RecordConfig(encoder:AudioEncoder.wav,
      sampleRate: 44100,
      numChannels: 1,);

      await record.start(
        config,
        path: path!);

      Timer(Duration(milliseconds: 5*len),()
      {
      record.stop();
      setState((){
        isRunning = false;
        count = 4;
        Navigator.push(context,
        MaterialPageRoute(builder:
        (context) => SecondPage(path: path!,
        bpm: bpm)
        )
        );
      }
      );
      }
      );
    }
  }


  Future<void> playSound() async
  {
    soloud.play(sound);
  }
  

  @override
  Widget build(BuildContext context)
  {
    return isRunning? Center(
      child:Text("$count",
      style: TextStyle(
        fontSize:30))):
      Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 20
              )
            ),
          onPressed:(() => play()),
          child: Text("Check your rhythm",
          style: TextStyle(
            fontSize: 17.5
          ))
          ),
          Slider(
            min:30,
            max:240,
            value: bpm,
            divisions: 210,
            onChanged:(double value)
            {
              setState(() => bpm = value);
            },
            activeColor: Colors.red
            ),
            Container(
              padding:EdgeInsets.all(20),
              color: Colors.black,
              child:Text('${bpm.round()}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20
              )
              ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:[
                IconButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.red
                    ),
                  onPressed:()
                  {
                    setState(()
                    {
                      if (bpm > 30)
                      {
                        --bpm;
                      }
                    },
                    );
                  },
                  icon: Icon(Icons.remove)
                  ),
                  IconButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.red
                    ),
                  onPressed:()
                  {
                    setState(()
                    {
                      if (bpm < 240)
                      {
                        ++bpm;
                      }
                    },
                    );
                  },
                  icon: Icon(Icons.add)
                )
              ]
            )
          ]
        )
      );
  }

  @override
  void dispose()
  {
    super.dispose();
    timer?.cancel();
    record.dispose();
    soloud.disposeAllSources();
  }
}


class SecondPage extends StatefulWidget
{
  final String path;
  final double bpm;
  const SecondPage({required this.path,
  required this.bpm,super.key});

  @override
  SecondPageState createState() => SecondPageState();
}


class SecondPageState extends State<SecondPage>
{
  final player = AudioPlayer();
  List<FlSpot> points = [];
  List<double> claps = [];
  List<double> clicks = [];
  bool isLoaded = false;
  int threshold = 5000;
  int sampleRate = 44100;
  double skipTime = 0.05;
  int score = 0;
  String grade = 'Not available';

  String getGrade(int score)
  {
    if (score >= 900)
    {
      return 'S';
    }
    else if (score >= 800)
    {
      return 'A';
    }
    else if (score >= 700)
    {
      return 'B';
    }
    else if (score >= 600)
    {
      return 'C';
    }
    else if (score >= 500)
    {
      return 'D';
    }
    else
    {
      return 'F';
    }
  }

  String getText()
  {
    if (claps.isEmpty)
    {
      return "You didn't clapped";
    }

    if (score >= 800)
    {
      return "Great job, keep up the good work";
    }
    else if (score >= 500)
    {
      return "Good, but you can do better";
    }

    return "Don't worry, work harder next time";
  }

  List<double> getClicks()
  {
    clicks.clear();
    for (int i = 1; i <= 4; ++i)
    {
      clicks.add(i*60/widget.bpm);
    }

    return clicks;
  }

  Future<List<int>> getSample() async
  {
    final bytes = await File(widget.path).readAsBytes();
    final header = ByteData.
    sublistView(Uint8List.fromList(bytes));
    final bitDepth = header.getUint16(34,Endian.little);
    final audioBytes = bytes.sublist(44);
    final data = ByteData.sublistView
    (Uint8List.fromList(audioBytes));

    final samples = <int>[];

    switch(bitDepth)
    {
      case 8:
        for (int i = 0; i < data.lengthInBytes; i += 1)
        {
          samples.add(data.getInt8(i));
        }
        break;
      case 16:
        for (int i = 0; i < data.lengthInBytes; i += 2)
        {
          samples.add(data.getInt16(i,Endian.little));
        }
        break;
      case 32:
        for (int i = 0; i < data.lengthInBytes; i += 4)
        {
          samples.add(data.getInt32(i,Endian.little));
        }
        break;
      default:
        for (int i = 0; i < data.lengthInBytes; i += 2)
        {
          samples.add(data.getInt16(i,Endian.little));
        }
    }

    return samples;
  }


  Future<void> detectClaps(List<int> samples) async
  {
    clicks = getClicks();

    for (int i = 0; i < samples.length; i++)
    {
      if (samples[i].abs() >= threshold)
      {
        bool skip = false;
        double time = i/sampleRate;
        for(int i = 0; i < 4; ++i)
        {
          if ((time-clicks[i]).abs() <= skipTime)
          {
            skip = true;
          }
        }

        if (skip) continue;
        int peakAbs = samples[i].abs();
        int peakIndex = i;
        int maybeEnd = i + (0.1*sampleRate).round();
        int end = maybeEnd < samples.length? maybeEnd: samples.length;
        for (int j = i; j < end; ++j)
        {
          bool skip = false;
          for(int i = 0; i < 4; ++i)
          {
            if ((j/sampleRate-clicks[i]).abs() <= skipTime)
            {
              skip = true;
            }
          }
          if (skip) continue;

          if (samples[j].abs() > peakAbs)
          {
            peakAbs = samples[j].abs();
            peakIndex = j;
          }
        }
        claps.add(peakIndex/sampleRate);
        i += (((30000/widget.bpm)/1000)*sampleRate).round();
      }
    }
  }


  Future<void> getWaveform() async
  {

    List<int> samples = await getSample();

    for (int i = 0; i < samples.length; i += 100)
    {
      double time = i / sampleRate;
      points.add(FlSpot(time,
      samples[i].abs().toDouble()));
    }

    await detectClaps(samples);

    double total = 0;
    int end = 4 < claps.length? 4: claps.length;
  
    for (int i = 0; i < end; i++)
    {
      total += (claps[i] - clicks[i]).abs();
    }

    int avg = 0;
    if (claps.isNotEmpty)
    {
      avg += (total/claps.length*1000).round();
      //avg is in milliseconds
      score = (1000-avg).clamp(0,1000);
      grade = getGrade(score);
    }

    setState(()=>isLoaded = true);
  }


  @override
  void initState()
  {
    super.initState();
    getClicks();
    getWaveform();
  }

  Future<void> playRecorded() async
  {
    await player.play(DeviceFileSource(widget.path));
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar:AppBar(
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.white,
        title: Text("Your analysis")
      ),
      body:Center(
        child:Column(
          mainAxisAlignment:MainAxisAlignment.center,
          children:[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.white
            ),
              onPressed:(() =>
              playRecorded()),
              child: Text("Play")),
            isLoaded? Column(
              children: [SizedBox(height:300,
              child:LineChart(
                LineChartData(
                  lineBarsData:[
                    LineChartBarData(
                      spots: points
                    )
                  ]
                )
              ),),
              SizedBox(height:20),
              Container(
              padding: EdgeInsets.all(20.00),
              color: score >= 500? Colors.green:
              Colors.red,
              child:Text("Your Grade: $grade",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold
              ),
              )
              ),
              SizedBox(height:20),
              Text(
              getText(),
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline
              )
              )
              ]
              ): 
            Text("Loading..."),
            //
          ]
        )
      )
    );
  }
}