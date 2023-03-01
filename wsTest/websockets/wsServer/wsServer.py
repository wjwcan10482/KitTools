import asyncio
import logging
import websockets

# 配置日志格式
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# 日志文件路径
LOG_FILE = '/var/log/test'

async def tail_logs(websocket, path):
    # 打开日志文件并跳到末尾
    with open(LOG_FILE, 'r') as f:
        f.seek(0, 2)

        while True:
            # 读取日志文件中新增的内容
            line = f.readline()
            if not line:
                await asyncio.sleep(0.1)
                continue

            # 发送新增内容到WebSocket客户端
            await websocket.send(line.rstrip())

async def main():
    # 启动WebSocket服务器
    async with websockets.serve(tail_logs, "178.105.97.4", 8765):
        await asyncio.Future()  # 阻塞直到服务器关闭

if __name__ == '__main__':
    asyncio.run(main())
