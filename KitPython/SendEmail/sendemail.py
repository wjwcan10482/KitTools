from tkinter import *
import smtplib

class Application(Frame):
    def __init__(self, master):
        super(Application, self).__init__(master)
        self.grid()
        self.create_widgets()
    
    def create_widgets(self):
        menubar = Menu(self)
        menubar.add_command(label='Send', command=self.send)
        menubar.add_command(label='Quit', command=self.quit)
        self.label1 = Label(self, text='The Quick E-mailer')
        self.label1.grid(row=0, columnspan=3)
        self.label2 = Label(self, text="Enter the recipients:")   
        self.label2.grid(row=2, column=0)
        self.label3 = Label(self, text="Enter the Subject:")   
        self.label3.grid(row=3, column=0)
        self.label4 = Label(self, text="Enter the message:")   
        self.label4.grid(row=4, column=0)
        self.recipients = Entry(self)
        self.subj = Entry(self)
        self.body = Text(self, width=50, height=10)
        self.recipients.grid(row=2, column=1, sticky=W)
        self.subj.grid(row=3, column=1, sticky=W)
        self.body.grid(row=5, column=0, columnspan=2)
        self.button1 = Button(self, text="Send message", command=self.send)
        self.button1.grid(row=6, column=0, sticky=W)
        self.recipients.focus_set()
        root.config(menu=menubar)

    def send(self):
        server = 'smtp.163.com'
        port = '25'
        sender = 'wjwcan10482@163.com'
        password = 'wjwcan10482'
        to = self.recipients.get()
        tolist = to.split(',')
        subject=self.subj.get()
        body = self.body.get('1.0', END)
        header = 'To:' + to + '\n'
        header = header + 'From:' + sender + '\n'
        header = header + 'Subject:' + subject + '\n'
        message = header + body

        smtpserver = smtplib.SMTP(server, port)
        smtpserver.ehlo()
        smtpserver.starttls()
        smtpserver.ehlo()
        smtpserver.login(sender, password)
        smtpserver.sendmail(sender, tolist, message)
        smtpserver.quit()
        self.body.delete('1.0', END)
        self.body.insert(END, 'Message sent')

root = Tk()
print("1111")
root.title('The Quick E-mailer')
root.geometry('500x300')

print("2222")
app = Application(root)
print("3333")
app.mainloop()