{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "cloudscan.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "cloudscan.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "cloudscan.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "cloudscan.labels" -}}
helm.sh/chart: {{ include "cloudscan.chart" . }}
{{ include "cloudscan.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "cloudscan.selectorLabels" -}}
app.kubernetes.io/name: {{ include "cloudscan.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Service-specific labels
*/}}
{{- define "cloudscan.service.labels" -}}
helm.sh/chart: {{ include "cloudscan.chart" . }}
{{ include "cloudscan.service.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "cloudscan.service.selectorLabels" -}}
app.kubernetes.io/name: {{ .serviceName }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: {{ .serviceName }}
app.kubernetes.io/part-of: cloudscan
{{- end }}

{{/*
Image name helper
*/}}
{{- define "cloudscan.image" -}}
{{- $registry := .Values.global.imageRegistry | default "docker.io" -}}
{{- $repository := .image.repository -}}
{{- $tag := .image.tag | default .Values.global.imageTag | default "latest" -}}
{{- printf "%s/%s:%s" $registry $repository $tag -}}
{{- end -}}

{{/*
Image pull policy
*/}}
{{- define "cloudscan.imagePullPolicy" -}}
{{- .Values.global.imagePullPolicy | default "IfNotPresent" -}}
{{- end -}}

{{/*
PostgreSQL connection environment variables
*/}}
{{- define "cloudscan.postgresql.env" -}}
- name: POSTGRES_HOST
  value: {{ include "cloudscan.fullname" . }}-postgresql
- name: POSTGRES_PORT
  value: "5432"
- name: POSTGRES_USER
  value: {{ .Values.postgresql.auth.username | quote }}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "cloudscan.fullname" . }}-postgresql
      key: password
- name: POSTGRES_DB
  value: {{ .Values.postgresql.auth.database | quote }}
- name: DATABASE_URL
  value: postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@$(POSTGRES_HOST):$(POSTGRES_PORT)/$(POSTGRES_DB)
{{- end -}}

{{/*
Redis connection environment variables
*/}}
{{- define "cloudscan.redis.env" -}}
{{- if .Values.redis.enabled }}
- name: REDIS_HOST
  value: {{ include "cloudscan.fullname" . }}-redis-master
- name: REDIS_PORT
  value: "6379"
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "cloudscan.fullname" . }}-redis
      key: redis-password
- name: REDIS_URL
  value: redis://:$(REDIS_PASSWORD)@$(REDIS_HOST):$(REDIS_PORT)/0
{{- end }}
{{- end -}}

{{/*
Common environment variables
*/}}
{{- define "cloudscan.common.env" -}}
- name: LOG_LEVEL
  value: {{ .Values.global.logLevel | default "info" | quote }}
- name: ENVIRONMENT
  value: {{ .Values.global.environment | default "production" | quote }}
{{- end -}}

{{/*
Security context for pods
*/}}
{{- define "cloudscan.podSecurityContext" -}}
runAsNonRoot: true
runAsUser: 1000
fsGroup: 1000
{{- end -}}

{{/*
Security context for containers
*/}}
{{- define "cloudscan.containerSecurityContext" -}}
runAsNonRoot: true
runAsUser: 1000
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
capabilities:
  drop:
  - ALL
{{- end -}}

{{/*
Liveness probe for HTTP services
*/}}
{{- define "cloudscan.livenessProbe" -}}
httpGet:
  path: {{ .path | default "/health" }}
  port: {{ .port }}
initialDelaySeconds: {{ .initialDelaySeconds | default 30 }}
periodSeconds: {{ .periodSeconds | default 30 }}
timeoutSeconds: {{ .timeoutSeconds | default 5 }}
failureThreshold: {{ .failureThreshold | default 3 }}
{{- end -}}

{{/*
Readiness probe for HTTP services
*/}}
{{- define "cloudscan.readinessProbe" -}}
httpGet:
  path: {{ .path | default "/ready" }}
  port: {{ .port }}
initialDelaySeconds: {{ .initialDelaySeconds | default 10 }}
periodSeconds: {{ .periodSeconds | default 10 }}
timeoutSeconds: {{ .timeoutSeconds | default 5 }}
failureThreshold: {{ .failureThreshold | default 3 }}
{{- end -}}

{{/*
Startup probe for HTTP services
*/}}
{{- define "cloudscan.startupProbe" -}}
httpGet:
  path: {{ .path | default "/health" }}
  port: {{ .port }}
initialDelaySeconds: {{ .initialDelaySeconds | default 10 }}
periodSeconds: {{ .periodSeconds | default 10 }}
timeoutSeconds: {{ .timeoutSeconds | default 5 }}
failureThreshold: {{ .failureThreshold | default 30 }}
{{- end -}}

{{/*
ServiceAccount name
*/}}
{{- define "cloudscan.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{ default (include "cloudscan.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
{{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
=============================================================================
Service-Specific Fullnames and Labels
=============================================================================
*/}}

{{/*
Orchestrator fullname
*/}}
{{- define "cloudscan.orchestrator.fullname" -}}
{{- printf "%s-orchestrator" (include "cloudscan.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cloudscan.orchestrator.labels" -}}
{{ include "cloudscan.labels" . }}
app.kubernetes.io/component: orchestrator
{{- end -}}

{{- define "cloudscan.orchestrator.selectorLabels" -}}
{{ include "cloudscan.selectorLabels" . }}
app.kubernetes.io/component: orchestrator
{{- end -}}

{{/*
API Gateway fullname
*/}}
{{- define "cloudscan.apigateway.fullname" -}}
{{- printf "%s-apigateway" (include "cloudscan.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cloudscan.apigateway.labels" -}}
{{ include "cloudscan.labels" . }}
app.kubernetes.io/component: apigateway
{{- end -}}

{{- define "cloudscan.apigateway.selectorLabels" -}}
{{ include "cloudscan.selectorLabels" . }}
app.kubernetes.io/component: apigateway
{{- end -}}

{{/*
Storage fullname
*/}}
{{- define "cloudscan.storage.fullname" -}}
{{- printf "%s-storage" (include "cloudscan.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cloudscan.storage.labels" -}}
{{ include "cloudscan.labels" . }}
app.kubernetes.io/component: storage
{{- end -}}

{{- define "cloudscan.storage.selectorLabels" -}}
{{ include "cloudscan.selectorLabels" . }}
app.kubernetes.io/component: storage
{{- end -}}

{{/*
WebSocket fullname
*/}}
{{- define "cloudscan.websocket.fullname" -}}
{{- printf "%s-websocket" (include "cloudscan.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cloudscan.websocket.labels" -}}
{{ include "cloudscan.labels" . }}
app.kubernetes.io/component: websocket
{{- end -}}

{{- define "cloudscan.websocket.selectorLabels" -}}
{{ include "cloudscan.selectorLabels" . }}
app.kubernetes.io/component: websocket
{{- end -}}

{{/*
UI fullname
*/}}
{{- define "cloudscan.ui.fullname" -}}
{{- printf "%s-ui" (include "cloudscan.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cloudscan.ui.labels" -}}
{{ include "cloudscan.labels" . }}
app.kubernetes.io/component: ui
{{- end -}}

{{- define "cloudscan.ui.selectorLabels" -}}
{{ include "cloudscan.selectorLabels" . }}
app.kubernetes.io/component: ui
{{- end -}}

{{/*
Runner fullname
*/}}
{{- define "cloudscan.runner.fullname" -}}
{{- printf "%s-runner" (include "cloudscan.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "cloudscan.runner.labels" -}}
{{ include "cloudscan.labels" . }}
app.kubernetes.io/component: runner
{{- end -}}

{{- define "cloudscan.runner.selectorLabels" -}}
{{ include "cloudscan.selectorLabels" . }}
app.kubernetes.io/component: runner
{{- end -}}

{{/*
=============================================================================
PostgreSQL Helpers (Enhanced)
=============================================================================
*/}}

{{/*
PostgreSQL host - returns onPrem postgresql host or external host
*/}}
{{- define "cloudscan.postgres.host" -}}
{{- if .Values.onPrem.postgresql -}}
{{- printf "%s-postgresql" (include "cloudscan.fullname" .) -}}
{{- else -}}
{{- .Values.global.postgres.host | required "global.postgres.host is required when onPrem.postgresql=false" -}}
{{- end -}}
{{- end -}}

{{/*
PostgreSQL secret name
*/}}
{{- define "cloudscan.postgres.secretName" -}}
{{- if .Values.global.postgres.existingSecret -}}
{{- .Values.global.postgres.existingSecret -}}
{{- else if .Values.onPrem.postgresql -}}
{{- printf "%s-postgresql" (include "cloudscan.fullname" .) -}}
{{- else -}}
{{- printf "%s-postgres-secret" (include "cloudscan.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
=============================================================================
Redis Helpers (Enhanced)
=============================================================================
*/}}

{{/*
Redis host
*/}}
{{- define "cloudscan.redis.host" -}}
{{- if .Values.onPrem.redis -}}
{{- printf "%s-redis-master" (include "cloudscan.fullname" .) -}}
{{- else -}}
{{- .Values.global.redis.host | required "global.redis.host is required when onPrem.redis=false" -}}
{{- end -}}
{{- end -}}

{{/*
Redis secret name
*/}}
{{- define "cloudscan.redis.secretName" -}}
{{- if .Values.global.redis.passwordSecret -}}
{{- .Values.global.redis.passwordSecret -}}
{{- else if .Values.onPrem.redis -}}
{{- printf "%s-redis" (include "cloudscan.fullname" .) -}}
{{- else -}}
{{- printf "%s-redis-secret" (include "cloudscan.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
=============================================================================
MinIO/S3 Storage Helpers
=============================================================================
*/}}

{{/*
MinIO endpoint URL
*/}}
{{- define "cloudscan.minio.endpoint" -}}
{{- if .Values.onPrem.minio -}}
{{- printf "http://%s-minio:9000" (include "cloudscan.fullname" .) -}}
{{- else -}}
{{- .Values.global.storage.s3.endpoint -}}
{{- end -}}
{{- end -}}

{{/*
Storage secret name
*/}}
{{- define "cloudscan.storage.secretName" -}}
{{- if .Values.global.storage.s3.existingSecret -}}
{{- .Values.global.storage.s3.existingSecret -}}
{{- else if .Values.onPrem.minio -}}
{{- printf "%s-minio" (include "cloudscan.fullname" .) -}}
{{- else -}}
{{- printf "%s-storage-secret" (include "cloudscan.fullname" .) -}}
{{- end -}}
{{- end -}}