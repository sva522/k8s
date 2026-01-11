apiVersion: apps/v1
kind: Deployment
metadata:
  name: vip-svc
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vip-svc
  template:
    metadata:
      labels:
        app: vip-svc
    spec:
      containers:
        - name: nginx
          image: nginx:stable-alpine
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 2
            periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: svc-vip-svc
  namespace: default
spec:
  type: LoadBalancer
  selector:
    app: vip-svc
  ports:
    - port: 80
      targetPort: 80
  loadBalancerIP: 192.168.14.1

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vip-admin
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vip-admin
  template:
    metadata:
      labels:
        app: vip-admin
    spec:
      containers:
        - name: nginx
          image: nginx:stable-alpine
          ports:
            - containerPort: 80
          readinessProbe:
            httpGet:
              path: /
              port: 80
            initialDelaySeconds: 2
            periodSeconds: 5

---
apiVersion: v1
kind: Service
metadata:
  name: svc-vip-admin
  namespace: default
spec:
  type: LoadBalancer
  selector:
    app: vip-admin
  ports:
    - port: 80
      targetPort: 80
  loadBalancerIP: 192.168.11.100
