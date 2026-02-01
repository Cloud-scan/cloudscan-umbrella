{{/*
Init container to wait for a service to be ready
Usage: {{ include "cloudscan.initContainer.waitForService" (dict "name" "orchestrator" "host" "cloudscan-orchestrator" "port" 9999) }}
*/}}
{{- define "cloudscan.initContainer.waitForService" -}}
- name: wait-for-{{ .name }}
  image: busybox:1.36
  command:
    - sh
    - -c
    - |
      echo "Waiting for {{ .name }} service at {{ .host }}:{{ .port }}..."
      until nc -z {{ .host }} {{ .port }}; do
        echo "{{ .name }} is unavailable - sleeping"
        sleep 2
      done
      echo "{{ .name }} is up - continuing"
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
{{- end }}

{{/*
Init container to wait for PostgreSQL
Usage: {{ include "cloudscan.initContainer.waitForPostgres" . }}
*/}}
{{- define "cloudscan.initContainer.waitForPostgres" -}}
- name: wait-for-postgres
  image: busybox:1.36
  command:
    - sh
    - -c
    - |
      echo "Waiting for PostgreSQL at {{ include "cloudscan.postgres.host" . }}:{{ .Values.global.postgres.port | default "5432" }}..."
      until nc -z {{ include "cloudscan.postgres.host" . }} {{ .Values.global.postgres.port | default "5432" }}; do
        echo "PostgreSQL is unavailable - sleeping"
        sleep 2
      done
      echo "PostgreSQL is up - continuing"
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
{{- end }}

{{/*
Init container to wait for Redis
Usage: {{ include "cloudscan.initContainer.waitForRedis" . }}
*/}}
{{- define "cloudscan.initContainer.waitForRedis" -}}
- name: wait-for-redis
  image: busybox:1.36
  command:
    - sh
    - -c
    - |
      echo "Waiting for Redis at {{ include "cloudscan.redis.host" . }}:{{ .Values.global.redis.port | default "6379" }}..."
      until nc -z {{ include "cloudscan.redis.host" . }} {{ .Values.global.redis.port | default "6379" }}; do
        echo "Redis is unavailable - sleeping"
        sleep 2
      done
      echo "Redis is up - continuing"
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
{{- end }}

{{/*
Init container to wait for MinIO
Usage: {{ include "cloudscan.initContainer.waitForMinio" . }}
*/}}
{{- define "cloudscan.initContainer.waitForMinio" -}}
{{- if .Values.onPrem.minio }}
- name: wait-for-minio
  image: busybox:1.36
  command:
    - sh
    - -c
    - |
      echo "Waiting for MinIO at {{ include "cloudscan.fullname" . }}-minio:9000..."
      until nc -z {{ include "cloudscan.fullname" . }}-minio 9000; do
        echo "MinIO is unavailable - sleeping"
        sleep 2
      done
      echo "MinIO is up - continuing"
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    allowPrivilegeEscalation: false
    capabilities:
      drop:
        - ALL
{{- end }}
{{- end }}
