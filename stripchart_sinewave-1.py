from tkinter import *
import tkinter
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import sys, time, math
from time import sleep
#start of this
import serial
import serial.tools.list_ports
from tkinter import messagebox
import subprocess
#subprocess.check_output(['ls','-l']) #all that is technically needed...
from subprocess import call
#end of this
import os
from os import path
import pygame
import speech_recognition as sr
from time import ctime
import time
from gtts import gTTS
import pyaudio
import sys
#import pyttsx

#import speech_recognition as sr

pygame.init()
chunk = 1024
FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 44100
RECORD_SECONDS = 5

xsize=1000
size = 1500
max_def=10
PORT = 'COM4'
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
ax.set_ylim(0, 250)
ax.set_xlim(0, size)###jump
ax.grid()
xdata, ydata = [], []




#------------------------------------------------------------------------------
def data_gen_else():
# file handle fh
    t1 = data_gen.t1
    with open('hello.txt', 'rw+') as ofile:
        values = ofile.readlines()
        cnt = 1
            
    while True:
        t1+=1
        value=int(values[cnt])
        cnt += 1
        
        if not values:
            break
    fh.close()
    yield t1, value

def run_else1(data):
    # update the data
    t1,line = data
    if t1>-1:
        xdata.append(t1)
        ydata.append(value)
        if t1>size: # Scroll to the left.
            ax1.set_xlim(t1-10, t1)
        line1.set_data(x1data, y1data)

    return line1,

def on_close_figure1(event):
    sys.exit(0)


data_gen.t1 = -1
fig1 = plt.figure()
fig1.canvas.mpl_connect('close_event', on_close_figure1)
ax1 = fig1.add_subplot(111)
line1, = ax1.plot([], [], lw=2)
ax.set_ylim(0, 250)
ax1.set_xlim(0, 500)###jump
ax1.grid()
x1data, y1data = [], []
ani1 = animation.FuncAnimation(fig1, run_else1, data_gen_else, blit=False, interval=100, repeat=False)
#-------------------------------------------------------------------------------

# Important: Although blit=True makes graphing faster, we need blit=False to prevent
# spurious lines to appear when resizing the stripchart.
ani = animation.FuncAnimation(fig, run, data_gen, blit=False, interval=100, repeat=False)



'''
def recording():
    p = pyaudio.PyAudio()

    stream = p.open(format=FORMAT,
                    channels=CHANNELS, 
                    rate=RATE, 
                    input=True,
                    output=True,
                    frames_per_buffer=chunk)

    for i in range(0, 44100 / chunk * RECORD_SECONDS):
        data = stream.read(chunk)
        # check for silence here by comparing the level with 0 (or some threshold) for 
        # the contents of data.
        # then write data or not to a file

    print "* done"

    stream.stop_stream()
    stream.close()
    p.terminate()
    '''
def speak(audioString):
    
    print(audioString)
    tts = gTTS(text=audioString, lang='en')
   
    tts.save("good.ogg")
    os.system("mpg321 good.ogg")
    #tts.save("audio.ogg")
    #pygame.mixer.init()
    #pygame.mixer.music.load("audio.ogg")
    #pygame.mixer.music.play()
    '''
    engine = pyttsx.init()
    engine.say(audioString)
    engine.runAndWait()
    '''
def everything_else():
    window = tkinter.Tk()
    window.title("Temperature Sensor")
    window.geometry("300x700")
    pygame.mixer.init()
    pygame.mixer.music.load("welcome_messege.ogg")
    pygame.mixer.music.play()
    #strin = ser.readline();
    def sel():
       selection = "Value = " + str(var.get())
       label.config(text = selection)
    def showing():
        fig.show()
    def showing_past():
        
        fig1.show()        
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
            strin = ser.readline()
            file = open(filename, 'a')
            #strin = ser.readline();
            file.write(strin.decode('ascii'))
            file.close()
            if not quit_button:
                logger.destroy()
            else:
                logger.after(1000, callback)
        logger.after(1000, callback)




        logger.mainloop()

    def current(strin):

        
        temperature = tkinter.Tk()
        temperature.geometry("300x300")
        temperature.title("current temperature")
        temperature.transient()
        temp = IntVar()


        def callback1():
            nonlocal  temperature
            #strin = ser.readline();
            #file.write(strin.decode('ascii'))
            #file.close()
            temp.set(int(strin.decode('ascii')))
            if not quiting:
                temperature.destroy()
            else:
                temperature.after(1000, callback1)
        temperature.after(1000, callback1)


        label=tkinter.Label(temperature, textvariable=temp, width=5, font=("Helvetica", 50), fg="blue").grid(row=0, column=0) #here
        quitting = tkinter.Button(temperature, height = "5", width = "20", text = "Quit", command=lambda temperature=temperature:quiting(temperature)).grid(row=2, column=0)





        

        temperature.mainloop()
    
    def printer(val):
        max_def = val

    def current_data():
        strin = ser.readline();
        print(strin.decode('ascii'));

    def assembly():
        #print (subprocess.check_call(["ls", "-l"]));
        os.popen("Hello.asm")
    def on_off():
        ser.write(b"1")

    def lacri():
        pygame.mixer.init()
        pygame.mixer.music.load("lacrimosa.ogg")
        pygame.mixer.music.play()
    def confu():
        pygame.mixer.init()
        pygame.mixer.music.load("confutatis.ogg")
        pygame.mixer.music.play()
    def irae():
        pygame.mixer.init()
        pygame.mixer.music.load("DiesIrae.ogg")
        pygame.mixer.music.play()
    def scream():
        pygame.mixer.init()
        pygame.mixer.music.load("scream.ogg")
        os.popen("scary.jpg")
        pygame.mixer.music.play()
    def stop():
        music.destroy()
    def Pause_music():
        pygame.mixer.music.pause()

    def UNPause_music():
        pygame.mixer.music.unpause()
    def go_away(music):
        pygame.mixer.music.stop()
        music.destroy()
    def voice():
        
        voicer = tkinter.Tk()
        voicer.title("listening")
        voicer.geometry("500x600")
        voicer.transient()
        def callback_voice():
            nonlocal  voicer
            #AUDIO_FILE = path.join(path.dirname(path.realpath(__file__)), "test.flac")
            r = sr.Recognizer()
            #with sr.AudioFile(AUDIO_FILE) as source:
            with sr.Microphone(device_index = 1, sample_rate = 44100, chunk_size = 512) as source:
                audio = r.record(source, duration = 3)
                #audio = r.record(source) # read the entire audio file

                try:
                    if (r.recognize_google(audio, language="en")) == "light":
                        ser.write(b"1")
                    print("You said " + r.recognize_google(audio, language="en"))
                except sr.UnknownValueError:
                    #print("Could not understand audio")
                    speak("I cannot understand you!")
                    tkinter.messagebox.showinfo("What did you say?", "Could not understand audio")
                except sr.RequestError as e:
                    print("Could not request results; {0}".format(e))
                #print(r.recognize_google(audio, language="en"))
            if not leaving:
                voicer.destroy()
            else:
                 voicer.after(1000, callback_voice)
        voicer.after(1000, callback_voice)
        #SAY = tkinter.Button(voicer, height = "5", width = "20", text = "Say Something", command=(audio = r.record(source, duration = 3)))
        #SAY.pack()
        leaving = tkinter.Button(voicer, height = "5", width = "20", text = "Quit", command=lambda voicer=voicer:quiting(voicer))
        leaving.pack()
        voicer.mainloop()
        #voicer.after(1000, callback_voice)
    def entertaining():
        music = tkinter.Tk()
        music.title("Musics")
        music.geometry("500x600")

        #var = StringVar()
        label = Label( music, text="Please choose a music while waiting for reflow oven",font=("Helvetica", 15), fg="blue", relief=FLAT )
        #var.set("Please choose a music while waiting for reflow oven, we have mozart, mozart and mozart")
        label.pack()
        larimosa = tkinter.Button(music, height = "5", width = "15", text = "1. Lacrimosa", command = lacri)
        larimosa.pack()
        comfutatis = tkinter.Button(music, height = "5", width = "15", text = "2. Confutatis", command = confu)
        comfutatis.pack()
        diesirae =  tkinter.Button(music, height = "5", width = "15", text = "3. Dies Irae", command = irae)
        diesirae.pack()
        tryit =  tkinter.Button(music, height = "5", width = "15", text = "4. Try It", command = scream)
        tryit.pack()
        Pause = tkinter.Button(music, height = "5", width = "15", text = "Pause music", command = Pause_music)
        Pause.pack()
        unPause = tkinter.Button(music, height = "5", width = "15", text = "Unpause music", command = UNPause_music)
        unPause.pack()
        leave = tkinter.Button(music, height = "5", width = "15", text = "leave", command = lambda music=music:go_away(music))
        leave.pack()
        music.mainloop()
    button1 = tkinter.Button(window, height = "5", width = "20", text = "Show Graph", command = showing)
    button1.pack()


    button4 = tkinter.Button(window, height = "5", width = "20", text = "Current Value", command=lambda window=window:current(strin))
    button4.pack()


    button5 = tkinter.Button(window, height = "5", width = "20", text = "Check Assembly code", command = assembly)
    button5.pack()

    button6 = tkinter.Button(window, height = "5", width = "20", text = "Log data", command=logging)
    button6.pack()

    button7 = tkinter.Button(window, height = "5", width = "20", text = "On/Off", command = on_off)
    button7.pack()

    button8 = tkinter.Button(window, height = "5", width = "20", text = "enternainment", command = entertaining)
    button8.pack()
    button9 = tkinter.Button(window, height = "5", width = "20", text = "voice", command = voice)
    button9.pack()
    button10 = tkinter.Button(window, height = "5", width = "20", text = "show last attempt", command = showing_past)
    button10.pack()

    #var = IntVar
    #scale = Scale(window, orient='horizontal', variable = var, command = printer )
    #scale.pack(anchor=CENTER)



    window.mainloop()


    
def show_entry_fields(Logan):
    if ((e1.get()== "Logan") | (e1.get()== "Gary")|(e1.get()== "Hugh")|(e1.get()== "Owen")|(e1.get()== "Cyrus")|(e1.get() == "Mattew")|(e1.get()=="JESUS")) & (e2.get()=="12345") :
        print("login successful")
        Logan.destroy()
        everything_else()
    else:
        pygame.mixer.init()
        pygame.mixer.music.load("nonono_password.ogg")
        pygame.mixer.music.play()
        tkinter.messagebox.showinfo("WRONG", "Wrong username or passwork")


logan = Tk()
logan.title("Login")
logan.geometry("300x100")
Label(logan, text="Username").grid(row=0)
Label(logan, text="Password").grid(row=1)

e1 = Entry(logan)
e2 = Entry(logan, show = '*')

e1.grid(row=0, column=1)
e2.grid(row=1, column=1)

#give_up = tkinter.Button(logan, text='I Give up', command=logan.destroy()).grid(row=3, column=0, sticky=W, pady=4)
not_up = tkinter.Button(logan, text='Login', command= lambda logan = logan: show_entry_fields(logan)).grid(row=3, column=1, sticky=W, pady=4)
#command=lambda logger=logger:quiting(logger)

logan.mainloop()
