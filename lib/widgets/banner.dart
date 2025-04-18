
import 'package:flutter/material.dart';

import '../utility/image_path.dart';

class Banner extends StatelessWidget {
  const Banner({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}