OBTW
This is solution for the '99 Bottles Of Beer' challenge from Code Golf:
http://codegolf.com/99-bottles-of-beer
TLDR

HAI 1.2

BTW recursive approach
HOW DUZ I bottle YR count
  BOTH SAEM count AN 1, O RLY?
    YA RLY
      VISIBLE "1 bottle of beer on the wall, 1 bottle of beer.:)" ...
        "Go to the store and buy some more, 99 bottles of beer on the wall."
    NO WAI
      I HAS A newCount ITZ DIFF OF count AN 1
      BOTH SAEM newCount AN 1, O RLY?
        YA RLY
          I HAS A s ITZ "1 bottle"
        NO WAI
          I HAS A s ITZ ":{newCount} bottles"
      OIC
      VISIBLE ":{count} bottles of beer on the wall, :{count} bottles of beer.:)" ...
        "Take one down and pass it around, :{s} of beer on the wall.:)"
      bottle newCount
  OIC
IF U SAY SO

bottle 99

KTHXBYE
