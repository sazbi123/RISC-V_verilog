#! /usr/bin/python3
# ./wraper.py [verilog_path] [clock_name] [kakko]

import os
import re
import sys

def main():
    args=sys.argv

    if len(args)<2:
        print("引数がない")
        exit()
    
    file_name=args[1]
    port_list=[]

    if len(args)==3:
        clk_name=args[2]
    else:
        clk_name=""
    
    if len(args)==4:
        kakko=args[3]
        clk_name=args[2]
    else:
        kakko=""
        clk_name=""

    try:
        with open(file_name,"r",encoding="utf8") as f1:
            verilog_data=f1.read()
    except FileNotFoundError:
        print("そのようなファイルはない")
        exit()
    
    verilog_data=verilog_data.replace("    ","")
    # 正規表現の"."に改行も含ませるre.DOTALL
    matches=re.findall(r"""module (.*?) \(\n(.*?)\n\);""",verilog_data,re.DOTALL)
    module_name=matches[0][0]
    ports=(matches[0][1]).split("\n")

    # モジュール宣言
    with open(f"{module_name}_tb.v","w",encoding="utf8") as f2:
        f2.write(f'`include "{module_name}.v"\n\n')

    # モジュール宣言
    with open(f"{module_name}_tb.v","a",encoding="utf8") as f2:
        f2.write(f"module {module_name}_tb ();\n")
    
    # reg，wire宣言
    for port in ports:
        port=port.split(" ")
        if port[0]=="input":
            # バスのとき
            if re.match(r"\[(.*?):(.*?)\]",port[2]):
                if port[3][-1]==",":
                    port_names=port[3][:-1]
                else:
                    port_names=port[3]

                for i in port_names.split(","):
                    port_list.append(i)

                with open(f"{module_name}_tb.v","a",encoding="utf8") as f3:
                    f3.write(f"    reg {port[2]} {port_names};\n")
            # バスでないとき（1bitのとき）
            else:
                if port[2][-1]==",":
                    port_names=port[2][:-1]
                else:
                    port_names=port[2]

                for i in port_names.split(","):
                    port_list.append(i)
                
                with open(f"{module_name}_tb.v","a",encoding="utf8") as f3:
                    f3.write(f"    reg {port_names};\n")
        elif port[0]=="output":
            # バスのとき
            if re.match(r"\[(.*?):(.*?)\]",port[2]):
                if port[3][-1]==",":
                    port_names=port[3][:-1]
                else:
                    port_names=port[3]

                for i in port_names.split(","):
                    port_list.append(i)

                with open(f"{module_name}_tb.v","a",encoding="utf8") as f3:
                    f3.write(f"    wire {port[2]} {port_names};\n")
            # バスでないとき（1bitのとき）
            else:
                if port[2][-1]==",":
                    port_names=port[2][:-1]
                else:
                    port_names=port[2]

                for i in port_names.split(","):
                    port_list.append(i)

                with open(f"{module_name}_tb.v","a",encoding="utf8") as f3:
                    f3.write(f"    wire {port_names};\n")
        elif port[0]=="inout":
            print("未実装")
            exit()
        else:
            print("定義されていない")
            exit()

    # 空行
    with open(f"{module_name}_tb.v","a",encoding="utf8") as f2:
        f2.write(f"\n")
    
    # インスタンス化
    with open(f"{module_name}_tb.v","a",encoding="utf8") as f2:
        f2.write(f"    {module_name} {module_name}(\n")
    
    for i in range(len(port_list)):
        with open(f"{module_name}_tb.v","a",encoding="utf8") as f2:
            if kakko=="":
                if i==len(port_list)-1:
                    f2.write(f"        .{port_list[i]}({port_list[i]})\n    );\n")
                else:
                    f2.write(f"        .{port_list[i]}({port_list[i]}),\n")
            else:
                if i==len(port_list)-1:
                    f2.write(f"        .{port_list[i]}()\n    );\n")
                else:
                    f2.write(f"        .{port_list[i]}(),\n")
    
    # 空行
    with open(f"{module_name}_tb.v","a",encoding="utf8") as f2:
        f2.write(f"\n")
    
    # always
    with open(f"{module_name}_tb.v","a",encoding="utf8") as f2:
        if clk_name=="":
            f2.write(f"    always begin\n        ;\n    end\n")
        else:
            f2.write(f"    always begin\n        {clk_name}=1'b0;\n        #1;\n        {clk_name}=1'b1;\n        #1;\n    end\n")
    
    # 空行
    with open(f"{module_name}_tb.v","a",encoding="utf8") as f2:
        f2.write(f"\n")
    
    # initial
    with open(f"{module_name}_tb.v","a",encoding="utf8") as f2:
        f2.write(f"    initial begin\n        $finish;\n    end\n")
    
    # 空行
    with open(f"{module_name}_tb.v","a",encoding="utf8") as f2:
        f2.write(f"\n")
    
    # iverilogのダンプ用記述
    with open(f"{module_name}_tb.v","a",encoding="utf8") as f2:
        f2.write(f'    initial begin\n        $dumpfile("{module_name}.vcd");\n        $dumpvars(0, {module_name}_tb);\n    end\n')
    
    # endmodule
    with open(f"{module_name}_tb.v","a",encoding="utf8") as f2:
        f2.write(f"endmodule\n")
    
    print("ラッパー生成完了")
    print(f"{re.findall(rf"(.*?/){module_name}.v",os.path.abspath(file_name))[0]}にラッパー{module_name}_tb.vを生成しました")

if __name__=="__main__":
    main()