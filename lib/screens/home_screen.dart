import 'package:flutter/material.dart';
import 'package:quizapp/screens/question_screen.dart';
import '../utility/image_path.dart';
import '../widgets/categories_card.dart';
import '../widgets/profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffedf3f6),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  const Profile(),

                  Container(
                    width: MediaQuery.of(context).size.width,

                    margin:
                        const EdgeInsets.only(top: 120, left: 20, right: 20),
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(30)),
                    child: Row(
                      children: [
                        Image.asset(
                          ImagesPath.banner,
                          height: 240,
                          width: 150,
                        ),
                        const Text(
                          "Play Quiz by\n guessing the image",
                          style: TextStyle(
                              color: Colors.white60,
                              fontSize: 15,
                              fontWeight: FontWeight.w500),
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Text(
                  "Top Quiz Categories",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 23,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => QuestionScreen(
                                      category: "Python",
                                    )));
                      },
                      child: const CategoriesCard(
                        title: "Python",
                        image: ImagesPath.python,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => QuestionScreen(
                                      category: "Dart",
                                    )));
                      },
                      child: const CategoriesCard(
                        title: "Dart",
                        image: ImagesPath.dart,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => QuestionScreen(
                                      category: "Java",
                                    )));
                      },
                      child: const CategoriesCard(
                        title: "Java",
                        image: ImagesPath.java,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => QuestionScreen(
                                      category: "JavaScript",
                                    )));
                      },
                      child: const CategoriesCard(
                        title: "JavaScript",
                        image: ImagesPath.javaScript,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => QuestionScreen(
                                      category: "PHP",
                                    )));
                      },
                      child: const CategoriesCard(
                        title: "PHP",
                        image: ImagesPath.php,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => QuestionScreen(
                                      category: "Swift",
                                    )));
                      },
                      child: const CategoriesCard(
                        title: "Swift",
                        image: ImagesPath.swift,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

