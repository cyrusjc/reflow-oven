from tkinter import *
import tkinter
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import sys, time, math
from time import sleep
import time 
#start of this
import serial
import serial.tools.list_ports
from tkinter import messagebox
import subprocess
#subprocess.check_output(['ls','-l']) #all that is technically needed...
from subprocess import call
#end of this
import kconvert
import os
'''--------------------------------
'''

xsize=400
size = 400
max_def=10
PORT = 'COM5'
try:
 ser.close();
except:
 print();
try:
 ser = serial.Serial(PORT, 115200, timeout=100)
except:
 print ('Serial port %s is not available' % PORT);
 portlist=list(serial.tools.list_ports.comports())
 print('Trying with port %s' % portlist[0][0]);
 ser = serial.Serial(portlist[0][0], 115200, timeout=100)
ser.isOpen()

def data_gen():
    t = data_gen.t
    while True:
       strin = ser.readline();
       t+=1
       #val=100.0*math.sin(t*2.0*3.1415/100.0)
       val=int(strin.decode('ascii'))
       yield t, val

def run(data):
    # update the data
    t,y = data
    if t>-1:
        xdata.append(t)
        ydata.append(y)
        if t>size: # Scroll to the left.
            ax.set_xlim(t-10, t)
        line.set_data(xdata, ydata)

    return line,

def on_close_figure(event):
    sys.exit(0)


data_gen.t = -1
fig = plt.figure()
fig.canvas.mpl_connect('close_event', on_close_figure)
ax = fig.add_subplot(111)
line, = ax.plot([], [], lw=2)
ax.set_ylim(-30, 400)
ax.set_xlim(0, size)###jump
ax.grid()
xdata, ydata = [], []

# Important: Although blit=True makes graphing faster, we need blit=False to prevent
# spurious lines to appear when resizing the stripchart.
ani = animation.FuncAnimation(fig, run, data_gen, blit=False, interval=100, repeat=False)
'''
    window = tkinter.Tk()
    window.title("Temperature Sensor")
    window.geometry("300x500")
    def sel():
       selection = "Value = " + str(var.get())
       label.config(text = selection)
    def showing():
        plt.show()
    def printing():
        print("blah")
    def new_window():
        new_win = tkinter.Tk()
        scroller = Scrollbar(new_win)
        scroller.pack( side = RIGHT, fill = Y )
        Lb1 = Listbox(new_win, height = "150", width = "150", yscrollcommand = scroller.set )
        Lb1.pack()
        new_win.title("Temp Sequence")
        new_win.geometry("150x150")
        
        ########################
        def update_txt(event = None):
            i = 0
            while i<=10: #try to think about the
                strin = ser_sig.readline();
                Lb1.insert(END, strin.decode('ascii'))
      
                i+=1
                Lb1.update_idletasks()
                scroller.config( command = Lb1.yview )
                sleep(0.5)
        new_win.after(10,update_txt)
        new_win.mainloop()

    def quiting(logger):
            logger.destroy()

    def clearing (logger, filename):
        file = open(filename, 'w')
        file.write("")
        file.close()

    def logging():
        filename = "hello.txt"
        logger = tkinter.Tk()
        logger.geometry("200x200")
        logger.title("Logging")
        logger.transient()

        
        quit_button = tkinter.Button(logger, height = "5", width = "20", text = "Stop", command=lambda logger=logger:quiting(logger))
        quit_button.pack()
        clear = tkinter.Button(logger, height = "5", width = "20", text = "clear", command=lambda logger=logger:clearing(logger, filename))
        clear.pack()
        def callback():
            nonlocal quit_button, logger
            file = open(filename, 'a')
            strin = ser_sig.readline();
            file.write(strin.decode('ascii'))
            file.close()
            if not quit_button:
                logger.destroy()
            else:
                logger.after(1000, callback)
        logger.after(1000, callback)




        logger.mainloop()
        
    def printer(val):
        max_def = val

    def current_data():
        strin = ser_sig.readline();
        print(strin.decode('ascii'));

    def assembly():
        #print (subprocess.check_call(["ls", "-l"]));
        os.popen("Hello.asm")
    def on_off():

        ser_sig.write(b"0xec")
        
    button1 = tkinter.Button(window, height = "5", width = "20", text = "Show Graph", command = showing)
    button1.pack()

    button4 = tkinter.Button(window, height = "5", width = "20", text = "Current Value", command = current_data)
    button4.pack()


    button5 = tkinter.Button(window, height = "5", width = "20", text = "Check Assembly code", command = assembly)
    button5.pack()

    button6 = tkinter.Button(window, height = "5", width = "20", text = "Log data", command = logging)
    button6.pack()

    button7 = tkinter.Button(window, height = "5", width = "20", text = "Switch", command = on_off)
    button7.pack()
    #var = IntVar
    #scale = Scale(window, orient='horizontal', variable = var, command = printer )
    #scale.pack(anchor=CENTER)



    window.mainloop()
'''
'''----------------------------
'''
top = Tk()
top.resizable(0,0)
top.title("Fluke_45/Tek_DMM40xx K-type Thermocouple")
top.geometry("1000x500")
#ATTENTION: Make sure the multimeter is configured at 9600 baud, 8-bits, parity none, 1 stop bit, echo Off

CJTemp = StringVar()
Temp = StringVar()
DMMout = StringVar()
portstatus = StringVar()
DMM_Name = StringVar()
connected=0
   
def Just_Exit():
    top.destroy()
    try:
        ser.close()
    except:
        dummy=0

def update_temp(strin):
    
    ktemp=int(strin.decode('ascii'))
    if ktemp < -200:  
        Temp.set("UNDER")
    elif ktemp > 1372:
        Temp.set("OVER")
    else:
        Temp.set(ktemp)
        #ser_sig.write(str(int(ktemp)).encode('ascii')+'\r\n'.encode('ascii')) #trickyyyyyyyyy whyyyyyyyy
               
    top.after(500, update_temp) # The multimeter is slow and the baud rate is slow: two measurement per second tops!

def FindPort(strin):
    time.sleep(0.2) # for the simulator
         
    pstring = strin.decode('ascii');
    ser.readline() # Read and discard the prompt "=>"
    ser.write(b"MEAS1?\r\n") # Request first value from multimeter
    top.after(1000,  update_temp(strin))

    top.after(5000,  FindPort(strin)) # Try again in 5 seconds
#=========================================================================
def sel():
    selection = "Value = " + str(var.get())
    label.config(text = selection)
def showing():
    plt.show()
def printing():
    print("blah")
def new_window():
    new_win = tkinter.Tk()
    scroller = Scrollbar(new_win)
    scroller.pack( side = RIGHT, fill = Y )
    Lb1 = Listbox(new_win, height = "150", width = "150", yscrollcommand = scroller.set )
    Lb1.pack()
    new_win.title("Temp Sequence")
    new_win.geometry("150x150")
        
        ########################
    def update_txt(event = None):
        i = 0
        while i<=10: #try to think about the
            strin = ser.readline();
            Lb1.insert(END, strin.decode('ascii'))
      
            i+=1
            Lb1.update_idletasks()
            scroller.config( command = Lb1.yview )
            sleep(0.5)
    new_win.after(10,update_txt)
    new_win.mainloop()

def quiting(logger):
        logger.destroy()

def clearing (logger, filename):
    file = open(filename, 'w')
    file.write("")
    file.close()

def logging():
    filename = "hello.txt"
    logger = tkinter.Tk()
    logger.geometry("200x200")
    logger.title("Logging")
    logger.transient()

        
    quit_button = tkinter.Button(logger, height = "5", width = "20", text = "Stop", command=lambda logger=logger:quiting(logger))
    quit_button.pack()
    clear = tkinter.Button(logger, height = "5", width = "20", text = "clear", command=lambda logger=logger:clearing(logger, filename))
    clear.pack()
    def callback():
        nonlocal quit_button, logger
        file = open(filename, 'a')
        strin = ser.readline();
        file.write(strin.decode('ascii'))
        file.close()
        if not quit_button:
            logger.destroy()
        else:
            logger.after(1000, callback)
    logger.after(1000, callback)




    logger.mainloop()

    
def printer(val):
    max_def = val

def current_data():
    strin = ser.readline();
    print(strin.decode('ascii'));

def assembly():
        #print (subprocess.check_call(["ls", "-l"]));
    os.popen("Hello.asm")
def on_off():

    ser.write(b"0xec")


#=============================================================================
Label(top, text="Cold Junction Temperature:").grid(row=1, column=0)
Entry(top, bd =1, width=7, textvariable=CJTemp).grid(row=2, column=0)
Label(top, text="Multimeter reading:").grid(row=3, column=0)
Label(top, text="xxxx", textvariable=DMMout, width=20, font=("Helvetica", 20), fg="red").grid(row=4, column=0)
Label(top, text="Thermocouple Temperature (C)").grid(row=5, column=0)
Label(top, textvariable=Temp, width=5, font=("Helvetica", 100), fg="blue").grid(row=6, column=0)
Label(top, text="xxxx", textvariable=portstatus, width=40, font=("Helvetica", 12)).grid(row=7, column=0)
Label(top, text="xxxx", textvariable=DMM_Name, width=40, font=("Helvetica", 12)).grid(row=8, column=0)
Button(top, width=11, text = "Exit", command = Just_Exit).grid(row=10, column=0)

        
Button1 = tkinter.Button(top, height = "5", width = "20", text = "Show Graph", command = showing).grid(row=11, column=0)


Button2 = tkinter.Button(top, height = "5", width = "20", text = "Current Value", command = current_data).grid(row=12, column=0)



Button3 = tkinter.Button(top, height = "5", width = "20", text = "Check Assembly code", command = assembly).grid(row=13, column=0)


Button4 = tkinter.Button(top, height = "5", width = "20", text = "Log data", command = logging).grid(row=14, column=0)


button7 = tkinter.Button(top, height = "5", width = "20", text = "Switch", command = on_off).grid(row=15, column=0)

#-----------------------------------------------------------------------------------------------------







#------------------------------------------------------------------------------------------------------
#CJTemp.set ("22")
#DMMout.set ("NO DATA")
#DMM_Name.set ("--------")

top.after(500,  FindPort(strin))
top.mainloop()
