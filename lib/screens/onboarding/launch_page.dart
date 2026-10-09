import 'package:flutter/material.dart';

import 'package:dab_fitness/config/onboarding_strings.dart';
import 'package:dab_fitness/screens/onboarding/welcome_page.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  late PageController _pageController;
  int currentIndex = 0;

  @override
  void initState() {
    _pageController = PageController(initialPage: 0);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        actions: currentIndex != 3
            ? <Widget>[
                Padding(
                  padding: EdgeInsets.only(right: 20, top: 20),
                  child: InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  WelcomePage()));
                    },
                    child: Text(
                      'Skip',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w400),
                    ),
                  ),
                )
              ]
            : null,
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          PageView(
            onPageChanged: (int page) {
              setState(() {
                currentIndex = page;
              });
            },
            controller: _pageController,
            children: <Widget>[
              makePage(
                  image: 'assets/images/launch-4.png',
                  title: OnboardingStrings.stepOneTitle,
                  content: OnboardingStrings.stepOneContent),
              makePage(
                  reverse: true,
                  image: 'assets/images/launch-1.png',
                  title: OnboardingStrings.stepTwoTitle,
                  content: OnboardingStrings.stepTwoContent),
              makePage(
                  image: 'assets/images/launch-3.jpg',
                  title: OnboardingStrings.stepThreeTitle,
                  content: OnboardingStrings.stepThreeContent),
              makePage(
                  image: 'assets/images/launch-2.jpg',
                  title: OnboardingStrings.stepThreeTitle,
                  content: ""),
            ],
          ),
          Container(
            margin: EdgeInsets.only(bottom: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildIndicator(),
            ),
          )
        ],
      ),
    );
  }

  Widget makePage({image, title, content, reverse = false}) {
    return Container(
      padding: EdgeInsets.only(left: 50, right: 50, bottom: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          !reverse
              ? Column(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Image.asset(image),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                  ],
                )
              : SizedBox(),
          SizedBox(
            height: 20,
          ),
          Text(
            content,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (currentIndex == 3)
            ElevatedButton(
              onPressed: () => Navigator.of(context)
                  .pushReplacementNamed(WelcomePage.routeName),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "Get Started !!!",
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          reverse
              ? Column(
                  children: <Widget>[
                    SizedBox(
                      height: 30,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Image.asset(image),
                    ),
                  ],
                )
              : SizedBox(),
        ],
      ),
    );
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: 6,
      width: isActive ? 30 : 6,
      margin: EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
          color: Colors.orange, borderRadius: BorderRadius.circular(5)),
    );
  }

  List<Widget> _buildIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < 4; i++) {
      if (currentIndex == i) {
        indicators.add(_indicator(true));
      } else {
        indicators.add(_indicator(false));
      }
    }

    return indicators;
  }
}
