import pymysql
import requests
#连接数据库
db = pymysql.connect(host='172.16.81.192',user='root', password='cl594oudadmin', db='dpm')
#定义游标
cursor = db.cursor()


# 查询
sql = 'select * from repository;'
cursor.execute(sql)
result=cursor.fetchall()
for item in result:
    index=item[0]
    url=item[4]
    try:
        r=requests.get(url+"/Packages",timeout=10)
    except:
        r="000"
    print("index: %s ,RL: %s, STATUS: %s"%(index,url,r))

#关闭游标
cursor.close()
#数据回滚
db.rollback()
#关闭数据库
db.close()


# 更新
# id=input("请输入要更新的id")
# k = input("请输入要更新的字段名：")
# v = input("请输入更新后的值:")
# try:
#  update = "update repository set "+k+"='"+v+"' where id="+id
#  print(update)
#  cursor.execute(update)
#  print('数据更新成功')
#  db.commit()#提交数据
# except:
#  print('数据更新失败')
# db.rollback()
# cursor.close()
# db.close()