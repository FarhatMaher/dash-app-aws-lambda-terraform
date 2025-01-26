from dash import Dash,html
import os

REQUESTS_PATHNAME_PREFIX = os.environ.get('REQUESTS_PATHNAME_PREFIX')

app = Dash(__name__, compress=False, requests_pathname_prefix=REQUESTS_PATHNAME_PREFIX)
app.title = "Dash on Lambda AWS."
app.layout = html.Div([
    html.H1('Dash'),
    html.Div('A web application framework for Python.'),
])
