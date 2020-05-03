"""
    This module implements the Report class.
"""

from pathlib import Path
from tempfile import NamedTemporaryFile

from bokeh.io import save
from bokeh.models import LayoutDOM
from bokeh.resources import CDN


class Report:
    """
    This class creates a customized Report object for the plot* functions
    """

    to_render: LayoutDOM

    def __init__(self, to_render: LayoutDOM) -> None:
        self.to_render = to_render

    def save(self, filename: str) -> None:
        """
        save function
        """
        save(self.to_render, filename=filename, resources=CDN, title="Report")

    def _repr_html_(self) -> str:
        # Windows forbids us open the file twice as the result bokeh cannot
        # write to the opened temporary file.
        with NamedTemporaryFile(suffix=".html", delete=False) as tmpf:
            pass

        save(self.to_render, filename=tmpf.name, resources=CDN, title="Report")
        with open(tmpf.name, "r") as f:
            output_html = f.read()

        # Delete the temporary file
        Path(tmpf.name).unlink()

        # embed into report template created by us here
        return output_html

        # from htmlmin.main import minify
        # import html
        # from IPython.display import HTML, display

        # wrapped_html = minify(
        #     output_html, remove_all_empty_space=True, remove_comments=True
        # )

        # src = html.escape(wrapped_html)

        # iframe = f'<iframe srcdoc="{src}" height="100%" width="100%" frameborder="0" allowfullscreen></iframe>'

        # display(HTML(iframe))
