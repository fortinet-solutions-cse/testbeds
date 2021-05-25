FROM python:3

COPY fit/* /fit/
RUN pip install --no-cache-dir -r /fit/requirements.txt

ENTRYPOINT /fit/myfit.sh
