import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/service/data.dart';

class QuestionScreen extends StatefulWidget {
  QuestionScreen({super.key, required this.category});

  String category;

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  bool show = false;

  getOnTheLoad() async {
    quizStream = await DatabaseMethods().getCategoryQuiz(widget.category);
    setState(() {});
  }

  @override
  void initState() {
    getOnTheLoad();
    super.initState();
  }

  Stream? quizStream;
  PageController controller = PageController();
  Widget allQuiz() {
    return streamBuilder;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004840),
      body: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 50, left: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFf35b32),
                            borderRadius: BorderRadius.circular(60)),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 100,
                    ),
                    Text(
                      widget.category,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24),
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Expanded(child: allQuiz()),
            ],
          ),
        ),
      ),
    );
  }
  StreamBuilder<dynamic> get streamBuilder {
    return StreamBuilder(
        stream: quizStream,
        builder: (context, AsyncSnapshot snapShot) {
          return snapShot.hasData
              ? PageView.builder(
              controller: controller,
              itemCount: snapShot.data.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot ds = snapShot.data.docs[index];
                return Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30)),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                ds["Image"],
                                height: 300,
                                width: MediaQuery.of(context).size.width,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          GestureDetector(
                            onTap: () {
                              show = true;
                              setState(() {});
                            },
                            child: show
                                ? Container(
                              padding: const EdgeInsets.all(15),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color:
                                      ds["correct"] == ds["option1"]
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1.5),
                                  borderRadius:
                                  BorderRadius.circular(15)),
                              child: Text(
                                ds["option1"],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                              ),
                            )
                                : Container(
                              padding: const EdgeInsets.all(15),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xFF818181),
                                      width: 1.5),
                                  borderRadius:
                                  BorderRadius.circular(15)),
                              child: Text(
                                ds["option1"],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 25,
                          ),
                          GestureDetector(
                            onTap: () {
                              show = true;
                              setState(() {});
                            },
                            child: show
                                ? Container(
                              padding: const EdgeInsets.all(15),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color:
                                      ds["correct"] == ds["option2"]
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1.5),
                                  borderRadius:
                                  BorderRadius.circular(15)),
                              child: Text(
                                ds["option2"],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                              ),
                            )
                                : Container(
                              padding: const EdgeInsets.all(15),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xFF818181),
                                      width: 1.5),
                                  borderRadius:
                                  BorderRadius.circular(15)),
                              child: Text(
                                ds["option1"],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 25,
                          ),
                          GestureDetector(
                            onTap: () {
                              show = true;
                              setState(() {});
                            },
                            child: show
                                ? Container(
                              padding: const EdgeInsets.all(15),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color:
                                      ds["correct"] == ds["option3"]
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1.5),
                                  borderRadius:
                                  BorderRadius.circular(15)),
                              child: Text(
                                ds["option3"],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                              ),
                            )
                                : Container(
                              padding: const EdgeInsets.all(15),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xFF818181),
                                      width: 1.5),
                                  borderRadius:
                                  BorderRadius.circular(15)),
                              child: Text(
                                ds["option3"],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 25,
                          ),
                          GestureDetector(
                            onTap: () {
                              show = true;
                              setState(() {});
                            },
                            child: show
                                ? Container(
                              padding: const EdgeInsets.all(15),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color:
                                      ds["correct"] == ds["option4"]
                                          ? Colors.green
                                          : Colors.red,
                                      width: 1.5),
                                  borderRadius:
                                  BorderRadius.circular(15)),
                              child: Text(
                                ds["option4"],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                              ),
                            )
                                : Container(
                              padding: const EdgeInsets.all(15),
                              width: MediaQuery.of(context).size.width,
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color(0xFF818181),
                                      width: 1.5),
                                  borderRadius:
                                  BorderRadius.circular(15)),
                              child: Text(
                                ds["option4"],
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                show=false;
                              });
                              controller.nextPage(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeIn);
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black),
                                      borderRadius:
                                      BorderRadius.circular(60)),
                                  child: const Icon(
                                    Icons.arrow_forward,
                                    color: Color(0xFF004840),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              })
              : Container();
        });
  }
}
