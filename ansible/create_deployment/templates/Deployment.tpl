kind: Deployment
apiVersion: apps/v1
metadata:
  name: {{ deployment_name  }}
spec:
  replicas: {{ deployment_replicas }}
  strategy:
    type: RollingUpdate
  selector:
    matchLabels:
      {{ deployment_label }}
  template:
    metadata:
      labels:
         {{ deployment_label }}
    spec:
      containers:
        - name: {{ deployment_name  }}
          image: {{ deployment_image }}
          imagePullPolicy: Always
