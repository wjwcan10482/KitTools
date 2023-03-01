#!/usr/bin/env python
# -*- encoding: utf-8 -*-
'''
@File    :   server.py
@Time    :   2022/08/29 10:13:24
@Author  :   Wangjin 
@Version :   1.0
@Contact :   wjwcan1048@163.com
@License :   (C)Copyright 2022-2032, Wangjin
@Desc    :   None
'''

# here put the import lib
from sanic import Sanic
from sanic.log import logger
from sanic.response import text,json,html
from jinja2 import Template, Environment, FileSystemLoader
import requests
import random
import string
import subprocess
from sanic import response


env = Environment(loader = FileSystemLoader('./templates/'))
app = Sanic(__name__)
app.static('/assets', './assets')

async def home(request):
    template = env.get_template('index.html')
    return html(template.render())

async def index(request):
    output = subprocess.run(["ls", "/tmp/urlc/"],capture_output=True)
    data = str(output.stdout,encoding = "utf-8").split("\n")[:-1]
    return text(str(data))

async def urlc(request):
    urli = str(request.body, encoding = "utf-8")
    r = requests.get(urli)
    if r.status_code == 200:
        filename = urli.split("/")[-1]
        r = requests.get(urli, stream=True)
        with open("/tmp/urlc/"+filename, "wb") as f:
            for chunk in r.iter_content(chunk_size=8):
                f.write(chunk)
        urlo = "http://178.105.97.4:9000/"+filename
    else:
        print("error: " + urli)
    return text(urlo)
    # return await response.file("/tmp/file")
    # template = env.get_template('urlc.html')
    # html(template.render(data="{}".format(str(request.body))))

app.add_route(home,'/home')
app.add_route(index,'/index')
app.add_route(urlc,'/urlc',methods=["POST",])

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, auto_reload=True)

