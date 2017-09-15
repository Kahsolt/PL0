#!/usr/bin/python3
#encoding: utf-8
import os
from tkinter import *
from tkinter import font
from tkinter import messagebox
from tkinter import filedialog

# Global Var
FONTSIZE='14'
PL0_TMP='.temp.pcd'
PL0_SCRIPT=PL0_TMP

# Tool func
def load():
    global PL0_SCRIPT
    PL0_SCRIPT = filedialog.askopenfilename(title='打开文件', filetypes=[('PL0', '*.pl0 *.pas'), ('All Files', '*')])
    print('File Path='+PL0_SCRIPT)
    try:
        tmpFile = open(PL0_SCRIPT, 'r')
        code = tmpFile.read()
        Text_Code.delete('0.0', END)
        Text_Code.insert('0.0', code)
    except:
        messagebox.showerror('错误', '无法打开此文件!')
    finally:
        tmpFile.close()

def savetmp():
    global PL0_SCRIPT, PL0_TMP
    code=Text_Code.get('0.0',END)
    try:
        tmpFile = open(PL0_TMP, 'w+')
        tmpFile.write(code)
        PL0_SCRIPT = PL0_TMP
    except:
        messagebox.showerror('错误', '无法打开临时文件!')
    finally:
        tmpFile.close()

def idehelp():
    messagebox.showinfo('帮助', '临时脚本编辑后必须先点击"保存为tmp"再运行！')

def run():
    global PL0_SCRIPT
    cmd="lua5.3 ./pl0c.lua "+PL0_SCRIPT
    print('Cmd='+cmd)
    ret=os.popen(cmd).read()
    Text_Shell.delete('0.0', END)
    Text_Shell.insert('0.0', ret)

# Main Entrance
Window = Tk()
Window.title('PL0 Poor IDE v0.1 by Kahsolt 2017/1/5')

ToolBar = Frame(Window)
button_run=Button(ToolBar, text="运行" ,command=run, background="red")
button_open=Button(ToolBar, text="打开...", command=load)
button_save=Button(ToolBar, text="保存为tmp", command=savetmp)
button_help=Button(ToolBar, text="帮助", command=idehelp)
button_run.pack(side=LEFT)
button_open.pack(side=LEFT)
button_save.pack(side=LEFT)
button_help.pack(side=RIGHT)
ToolBar.pack(side=TOP, fill=X)

Font=font.Font(font=('Fixdsys', FONTSIZE, font.NORMAL))
Panel = PanedWindow(Window)
Text_Code=Text(Panel,width=40,height=15,font=Font)
Text_Shell=Text(Panel,bg='black',fg='white',width=30,font=Font)
Panel.add(Text_Code)
Panel.add(Text_Shell)
Panel.pack(fill=BOTH, expand=1)

Window.mainloop()

# try to clean tmpfs
try:
    os.remove(PL0_TMP)
except:
    pass