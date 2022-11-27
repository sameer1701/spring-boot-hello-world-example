apiVersion: v1
kind: Service
metadata:
  name: {{ svc_name }}
spec:
  ports:
  - port: {{ svc_port }}
    protocol: TCP
    targetPort: {{ svc_tar_port }}
  selector:
    {{ deployment_label }}
  type: {{ svc_type }}
