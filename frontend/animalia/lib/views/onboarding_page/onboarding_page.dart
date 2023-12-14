import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: <Widget>[
          _buildPage(
              title: "Bem-vindo ao Animalia!",
              description: "Descubra o mundo animal.",
              textColor: Colors.white),
          _buildPage(
              title: "Conecte-se com outros",
              description:
                  "Faça amizades e conecte-se com outros amantes de animais.",
              textColor: Colors.white),
          _buildPage(
              title: "Comece agora",
              description: "Crie sua conta e comece a explorar!",
              textColor: Colors.white),
        ],
      ),
      backgroundColor: Colors.black,
      bottomSheet: _currentPage != 2
          ? _buildBottomSheet()
          : InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
              child: Container(
                height: 80.0,
                color: Colors.white,
                alignment: Alignment.center,
                child: const Text(
                  "Continuar",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildPage(
      {required String title,
      required String description,
      required Color textColor}) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 30.0,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20.0),
          Text(
            description,
            style: TextStyle(
              fontSize: 18.0,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      height: 80.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: List.generate(
              3,
              (index) => _buildPageIndicator(index == _currentPage),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _pageController.animateToPage(
                _currentPage + 1,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.white),
              foregroundColor: MaterialStateProperty.all(Colors.black),
            ),
            child: const Text(
              "Continuar",
              style: TextStyle(
                fontSize: 20.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      height: 10.0,
      width: isActive ? 20.0 : 10.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.grey,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
}
