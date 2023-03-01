from sanic import Sanic
from jinja2 import Template, Environment, FileSystemLoader
from sanic.response import text,html

env = Environment(loader = FileSystemLoader('./templates/'))
app = Sanic("jinja")

@app.route("/")
async def test(request):
    template = env.get_template('index.html')
    return html(template.render(name="wangjin1111"))

# Start Server
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=True, auto_reload=True)