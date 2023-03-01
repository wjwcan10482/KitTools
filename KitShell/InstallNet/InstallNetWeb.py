from flask import Flask, redirect, url_for, request, Response
import time
import subprocess
import paramiko
app = Flask(__name__)


@app.route('/')
def hello_world():
    return """
<html>
   <body>
      <form action = "http://localhost:5000/conserver" method = "post">
<div>
ssh_ip:<input type = "text" name = "ssh_ip" /></div>
<div>ssh_user:<input type = "text" name = "ssh_user" /></div>
<div>ssh_pass:<input type = "text" name = "ssh_pass" />
</div>
<div>
<input type = "submit" value = "submit" />
</div>
      </form>
   </body>
</html>
"""

@app.route('/conserver',methods = ['POST', 'GET'])
# 视图函数，从POST方法中获取请求表单的nm变量的值，并重定向到success(name)视图函数
def conserver():
   if request.method == 'POST':
      ssh_ip = request.form['ssh_ip']
      ssh_user = request.form['ssh_user']
      ssh_pass = request.form['ssh_pass']
      #return redirect(url_for('success',name = ssh_ip))
      ssh = paramiko.SSHClient()
      ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
      # 建立连接
      ssh.connect(ssh_ip,22,ssh_user,ssh_pass,timeout = 10)
      #输入linux命令
      installcmd="""
      wget http://172.16.81.81:8000/InstallNet.sh -P /home/;
      wget http://172.16.29.111:8000/feiteng/pool/base/sshpass_1.05-1kord_arm64.deb -P /home;
      sudo dpkg -i /home/sshpass_1.05-1kord_arm64.deb;
      chmod a+x /home/InstallNet.sh;
      bash /home/InstallNet.sh -k juniper -v aarch64 -a --ip-addr %s --ip-mask 255.255.255.0 --ip-gate 178.102.128.1;
      reboot
      """ % ssh_ip
      stdin,stdout,stderr = ssh.exec_command(installcmd)
      # 输出命令执行结果
      # return "连接服务区成功" 
      # stdin,stdout,stderr = ssh.exec_command('ls -a')
      # return "执行命令 %s" % stdin
      result = stdout.read()
      return "%s" % bytes.decode(result)
   else:
      user = request.args.get('nm')
      return redirect(url_for('success',name = user))


if __name__ == '__main__':
    app.debug = True
    app.run()
