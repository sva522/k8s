FROM python:3.13-slim
WORKDIR /app
RUN mkdir /app/data
COPY simple_app.py .
RUN pip install flask
ENV PYTHONUNBUFFERED=1 
CMD ["python", "simple_app.py"]
