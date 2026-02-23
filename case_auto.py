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
    text=list(set(text))
    # print(set(text),len(set(text)))
    # print((text),len(text))

    with open(f"{args[1]}.txt","w",encoding="utf8") as f2:
        for i in range(len(text)):
            text[i]=f"12'b{text[i]}: begin\n    ;\nend"
        
        f2.write("\n".join(text))

if __name__=="__main__":
    main()