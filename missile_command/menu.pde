void drawMenu() {

  HighScores currentHS = highScoresObjs.get(hsIndex);
  String[] scores = currentHS.arrayPairToStr();


  fill(255);
  textSize(30);

  // all the text on my menu
  String scoretxt = "Score: " + actualScore;
  String hscoretxt = "Highscores:";
  String menutxt = "Press space to start" + menuTxt2();
  String cfgtxt = "Current config (TAB): " + cfgs[cfgIndex] + " ("+(cfgIndex+1)+"/"+cfgs.length+")";
  String topTenScoreText = "You got a score in the top ten!";
  String typePrompt = "Enter your name/initials:";

  int topTextHeight = 70;



  // hide the menu stuff when the user is typing
  if (userTyping) {
    displayedUserText = typedText.toUpperCase();
    textSize(35);
    text(displayedUserText, centreText(displayedUserText), 460);
    text(typePrompt, centreText(typePrompt), 420);
  } else {

    if (topTenScore && hsIndex < 3) {
      text(topTenScoreText, centreText(topTenScoreText), height-floorHeight-90);
    }

    currentHS.drawMenuInstructions(90);
    
    text(scoretxt, centreText(scoretxt), height-floorHeight-60);
    text(menutxt, centreText(menutxt), topTextHeight + 120);
    
    textSize(20);
    text(cfgtxt, 5, 22);

    if ( hsIndex < 3 ) {
      text(hscoretxt, centreText(hscoretxt), topTextHeight + 180);


      for (int i=0; i<scores.length; i++) {
        if (i==10) {
          break;
        }
        color textColour = color(255);

        // top three scores get gold, silver, bronze
        if (i==0) {
          textColour = color(255, 223, 0);
        } else if (i==1) {
          textColour = color(196, 202, 230);
        } else if (i==2) {
          textColour = color(176, 141, 87);
        }

        fill(textColour);

        text(scores[i], centreText(scores[i]), topTextHeight + 210 + (i*30));
      }
    }
  }
}


int centreText( String txt ) {
  // this centers the score to the middle of the screen constantly by getting its width
  return int(width/2-textWidth(txt)/2);
}
