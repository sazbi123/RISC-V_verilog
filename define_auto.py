#! /usr/bin/python3

import sys
import math

def main():
    args=sys.argv

    if len(args)<2:
        print("引数が足りない")
        exit()
    
    with open(args[1],"r",encoding="utf8") as f1:
        text=f1.read()
    
    text=text.split("\n")
    width=math.ceil(math.log2(len(text)))
    # 値指定用
    width=8
    offset=3

    with open(f"{args[1]}.txt","w",encoding="utf8") as f2:
        for i in range(len(text)):
            text[i]=f"`define {text[i]} {width}'d{i+offset}"
        
        f2.write("\n".join(text))

if __name__=="__main__":
    main()