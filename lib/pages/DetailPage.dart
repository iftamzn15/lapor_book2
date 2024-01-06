import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lapor_book/components/status_dialog.dart';
import 'package:lapor_book/components/styles.dart';
import 'package:lapor_book/components/vars.dart';
import 'package:lapor_book/models/akun.dart';
import 'package:lapor_book/models/laporan.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({super.key});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _firestore = FirebaseFirestore.instance;

  bool isShow = true;
  late Laporan laporan;

  Future launch(String url) async {
    if (url == '') return;
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Tidak dapat memanggil $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final Akun akun = arguments['akun'];

    setState(() {
      laporan = arguments['laporan'];
    });

    laporan.likes?.forEach((element) {
      if (element.email == akun.email) {
        print(element.email);
        setState(() {
          isShow = false;
        });
      }
    });

    void addLikes() async {
      CollectionReference transaksiCollection =
          _firestore.collection('laporan');
      try {
        await transaksiCollection.doc(laporan.docId).update({
          'likes': FieldValue.arrayUnion([
            {
              'email': akun.email,
              'nama': akun.nama,
              'timestamp': DateTime.now()
            }
          ])
        });

        setState(() {
          isShow = !isShow;
        });
      } catch (e) {
        print(e);
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          "Detail Laporan",
          style: headerStyle(level: 3, dark: false),
        ),
        centerTitle: true,
      ),
      floatingActionButton: isShow
          ? FloatingActionButton(
              backgroundColor: Colors.orangeAccent,
              onPressed: () {
                addLikes();
              },
              child: Icon(Icons.favorite))
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(30),
            child: Column(
              children: [
                Text(
                  laporan.judul,
                  style: headerStyle(level: 2),
                ),
                SizedBox(
                  height: 15,
                ),
                laporan.gambar != ''
                    ? Image.network(
                        laporan.gambar!,
                      )
                    : Image.asset(
                        'assets/istock-default.jpg',
                      ),
                SizedBox(
                  height: 15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    textStatus(
                        laporan.status,
                        laporan.status == 'Posted'
                            ? warnaStatus[0]
                            : laporan.status == 'Process'
                                ? warnaStatus[1]
                                : warnaStatus[2],
                        Colors.white),
                    textStatus(laporan.instansi, Colors.white, Colors.black),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                ListTile(
                  title: Text('Nama Pelapor'),
                  subtitle: Text(laporan.nama),
                  leading: Icon(Icons.person),
                ),
                ListTile(
                  title: Text('Tanggal'),
                  subtitle: Text(
                    DateFormat('dd MMMM yyyy').format(laporan.tanggal),
                  ),
                  leading: Icon(Icons.date_range),
                  trailing: IconButton(
                    onPressed: () {
                      launch(laporan.maps);
                    },
                    icon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(
                  height: 50,
                ),
                Text(
                  'Deskripsi',
                  style: headerStyle(level: 2),
                ),
                SizedBox(
                  height: 15,
                ),
                Text(laporan.deskripsi ?? ''),
                SizedBox(
                  height: 15,
                ),
                if (akun.role == 'admin')
                  Container(
                    width: 250,
                    child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return StatusDialog(
                                  laporan: laporan,
                                );
                              });
                        },
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: Text('Ubah status')),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container textStatus(String text, var bgColor, var fgColor) {
    return Container(
      alignment: Alignment.center,
      width: 150,
      decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(width: 1, color: primaryColor),
          borderRadius: BorderRadius.circular(15)),
      child: Text(
        text,
        style: TextStyle(color: fgColor),
      ),
    );
  }
}
